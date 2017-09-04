# Gitlab::Git::Repository is a wrapper around native Rugged::Repository object
require 'tempfile'
require 'forwardable'
require "rubygems/package"

module Gitlab
  module Git
    class Repository
      include Gitlab::Git::Popen

      ALLOWED_OBJECT_DIRECTORIES_VARIABLES = %w[
        GIT_OBJECT_DIRECTORY
        GIT_ALTERNATE_OBJECT_DIRECTORIES
      ].freeze
      SEARCH_CONTEXT_LINES = 3

      NoRepository = Class.new(StandardError)
      InvalidBlobName = Class.new(StandardError)
      InvalidRef = Class.new(StandardError)

      # Full path to repo
      attr_reader :path

      # Directory name of repo
      attr_reader :name

      # Rugged repo object
      attr_reader :rugged

      attr_reader :storage

      # 'path' must be the path to a _bare_ git repository, e.g.
      # /path/to/my-repo.git
      def initialize(storage, relative_path)
        @storage = storage
        @relative_path = relative_path

        storage_path = Gitlab.config.repositories.storages[@storage]['path']
        @path = File.join(storage_path, @relative_path)
        @name = @relative_path.split("/").last
        @attributes = Gitlab::Git::Attributes.new(path)
      end

      delegate  :empty?,
                :bare?,
                to: :rugged

      delegate :exists?, to: :gitaly_repository_client

      # Default branch in the repository
      def root_ref
        @root_ref ||= gitaly_migrate(:root_ref) do |is_enabled|
          if is_enabled
            gitaly_ref_client.default_branch_name
          else
            discover_default_branch
          end
        end
      end

      def rugged
        @rugged ||= circuit_breaker.perform do
          Rugged::Repository.new(path, alternates: alternate_object_directories)
        end
      rescue Rugged::RepositoryError, Rugged::OSError
        raise NoRepository.new('no repository for such path')
      end

      def circuit_breaker
        @circuit_breaker ||= Gitlab::Git::Storage::CircuitBreaker.for_storage(storage)
      end

      # Returns an Array of branch names
      # sorted by name ASC
      def branch_names
        gitaly_migrate(:branch_names) do |is_enabled|
          if is_enabled
            gitaly_ref_client.branch_names
          else
            branches.map(&:name)
          end
        end
      end

      # Returns an Array of Branches
      def branches
        gitaly_migrate(:branches) do |is_enabled|
          if is_enabled
            gitaly_ref_client.branches
          else
            branches_filter
          end
        end
      end

      def reload_rugged
        @rugged = nil
      end

      # Directly find a branch with a simple name (e.g. master)
      #
      # force_reload causes a new Rugged repository to be instantiated
      #
      # This is to work around a bug in libgit2 that causes in-memory refs to
      # be stale/invalid when packed-refs is changed.
      # See https://gitlab.com/gitlab-org/gitlab-ce/issues/15392#note_14538333
      def find_branch(name, force_reload = false)
        reload_rugged if force_reload

        rugged_ref = rugged.branches[name]
        if rugged_ref
          target_commit = Gitlab::Git::Commit.find(self, rugged_ref.target)
          Gitlab::Git::Branch.new(self, rugged_ref.name, rugged_ref.target, target_commit)
        end
      end

      def local_branches(sort_by: nil)
        gitaly_migrate(:local_branches) do |is_enabled|
          if is_enabled
            gitaly_ref_client.local_branches(sort_by: sort_by)
          else
            branches_filter(filter: :local, sort_by: sort_by)
          end
        end
      end

      # Returns the number of valid branches
      def branch_count
        gitaly_migrate(:branch_names) do |is_enabled|
          if is_enabled
            gitaly_ref_client.count_branch_names
          else
            rugged.branches.count do |ref|
              begin
                ref.name && ref.target # ensures the branch is valid

                true
              rescue Rugged::ReferenceError
                false
              end
            end
          end
        end
      end

      # Returns the number of valid tags
      def tag_count
        gitaly_migrate(:tag_names) do |is_enabled|
          if is_enabled
            gitaly_ref_client.count_tag_names
          else
            rugged.tags.count
          end
        end
      end

      # Returns an Array of tag names
      def tag_names
        gitaly_migrate(:tag_names) do |is_enabled|
          if is_enabled
            gitaly_ref_client.tag_names
          else
            rugged.tags.map { |t| t.name }
          end
        end
      end

      # Returns an Array of Tags
      #
      # Gitaly migration: https://gitlab.com/gitlab-org/gitaly/issues/390
      def tags
        gitaly_migrate(:tags) do |is_enabled|
          if is_enabled
            tags_from_gitaly
          else
            tags_from_rugged
          end
        end
      end

      # Returns true if the given tag exists
      #
      # name - The name of the tag as a String.
      def tag_exists?(name)
        !!rugged.tags[name]
      end

      # Returns true if the given branch exists
      #
      # name - The name of the branch as a String.
      def branch_exists?(name)
        rugged.branches.exists?(name)

      # If the branch name is invalid (e.g. ".foo") Rugged will raise an error.
      # Whatever code calls this method shouldn't have to deal with that so
      # instead we just return `false` (which is true since a branch doesn't
      # exist when it has an invalid name).
      rescue Rugged::ReferenceError
        false
      end

      # Returns an Array of branch and tag names
      def ref_names
        branch_names + tag_names
      end

      def has_commits?
        !empty?
      end

      # Discovers the default branch based on the repository's available branches
      #
      # - If no branches are present, returns nil
      # - If one branch is present, returns its name
      # - If two or more branches are present, returns current HEAD or master or first branch
      def discover_default_branch
        names = branch_names

        return if names.empty?

        return names[0] if names.length == 1

        if rugged_head
          extracted_name = Ref.extract_branch_name(rugged_head.name)

          return extracted_name if names.include?(extracted_name)
        end

        if names.include?('master')
          'master'
        else
          names[0]
        end
      end

      def rugged_head
        rugged.head
      rescue Rugged::ReferenceError
        nil
      end

      def archive_prefix(ref, sha)
        project_name = self.name.chomp('.git')
        "#{project_name}-#{ref.tr('/', '-')}-#{sha}"
      end

      def archive_metadata(ref, storage_path, format = "tar.gz")
        ref ||= root_ref
        commit = Gitlab::Git::Commit.find(self, ref)
        return {} if commit.nil?

        prefix = archive_prefix(ref, commit.id)

        {
          'RepoPath' => path,
          'ArchivePrefix' => prefix,
          'ArchivePath' => archive_file_path(prefix, storage_path, format),
          'CommitId' => commit.id
        }
      end

      def archive_file_path(name, storage_path, format = "tar.gz")
        # Build file path
        return nil unless name

        extension =
          case format
          when "tar.bz2", "tbz", "tbz2", "tb2", "bz2"
            "tar.bz2"
          when "tar"
            "tar"
          when "zip"
            "zip"
          else
            # everything else should fall back to tar.gz
            "tar.gz"
          end

        file_name = "#{name}.#{extension}"
        File.join(storage_path, self.name, file_name)
      end

      # Return repo size in megabytes
      def size
        size = gitaly_migrate(:repository_size) do |is_enabled|
          if is_enabled
            size_by_gitaly
          else
            size_by_shelling_out
          end
        end

        (size.to_f / 1024).round(2)
      end

      # Use the Rugged Walker API to build an array of commits.
      #
      # Usage.
      #   repo.log(
      #     ref: 'master',
      #     path: 'app/models',
      #     limit: 10,
      #     offset: 5,
      #     after: Time.new(2016, 4, 21, 14, 32, 10)
      #   )
      #
      # Gitaly migration: https://gitlab.com/gitlab-org/gitaly/issues/446
      def log(options)
        default_options = {
          limit: 10,
          offset: 0,
          path: nil,
          follow: false,
          skip_merges: false,
          disable_walk: false,
          after: nil,
          before: nil
        }

        options = default_options.merge(options)
        options[:limit] ||= 0
        options[:offset] ||= 0

        raw_log(options).map { |c| Commit.decorate(self, c) }
      end

      def count_commits(options)
        gitaly_migrate(:count_commits) do |is_enabled|
          if is_enabled
            count_commits_by_gitaly(options)
          else
            count_commits_by_shelling_out(options)
          end
        end
      end

      def sha_from_ref(ref)
        rev_parse_target(ref).oid
      end

      # Return the object that +revspec+ points to.  If +revspec+ is an
      # annotated tag, then return the tag's target instead.
      def rev_parse_target(revspec)
        obj = rugged.rev_parse(revspec)
        Ref.dereference_object(obj)
      end

      # Return a collection of Rugged::Commits between the two revspec arguments.
      # See http://git-scm.com/docs/git-rev-parse.html#_specifying_revisions for
      # a detailed list of valid arguments.
      #
      # Gitaly note: JV: to be deprecated in favor of Commit.between
      def rugged_commits_between(from, to)
        walker = Rugged::Walker.new(rugged)
        walker.sorting(Rugged::SORT_NONE | Rugged::SORT_REVERSE)

        sha_from = sha_from_ref(from)
        sha_to = sha_from_ref(to)

        walker.push(sha_to)
        walker.hide(sha_from)

        commits = walker.to_a
        walker.reset

        commits
      end

      # Counts the amount of commits between `from` and `to`.
      def count_commits_between(from, to)
        Commit.between(self, from, to).size
      end

      # Returns the SHA of the most recent common ancestor of +from+ and +to+
      def merge_base_commit(from, to)
        rugged.merge_base(from, to)
      end

      # Gitaly note: JV: check gitlab-ee before removing this method.
      def rugged_is_ancestor?(ancestor_id, descendant_id)
        return false if ancestor_id.nil? || descendant_id.nil?

        merge_base_commit(ancestor_id, descendant_id) == ancestor_id
      end

      # Returns true is +from+ is direct ancestor to +to+, otherwise false
      def is_ancestor?(from, to)
        gitaly_commit_client.is_ancestor(from, to)
      end

      # Return an array of Diff objects that represent the diff
      # between +from+ and +to+.  See Diff::filter_diff_options for the allowed
      # diff options.  The +options+ hash can also include :break_rewrites to
      # split larger rewrites into delete/add pairs.
      def diff(from, to, options = {}, *paths)
        Gitlab::Git::DiffCollection.new(diff_patches(from, to, options, *paths), options)
      end

      # Returns a RefName for a given SHA
      def ref_name_for_sha(ref_path, sha)
        raise ArgumentError, "sha can't be empty" unless sha.present?

        gitaly_migrate(:find_ref_name) do |is_enabled|
          if is_enabled
            gitaly_ref_client.find_ref_name(sha, ref_path)
          else
            args = %W(#{Gitlab.config.git.bin_path} for-each-ref --count=1 #{ref_path} --contains #{sha})

            # Not found -> ["", 0]
            # Found -> ["b8d95eb4969eefacb0a58f6a28f6803f8070e7b9 commit\trefs/environments/production/77\n", 0]
            Gitlab::Popen.popen(args, @path).first.split.last
          end
        end
      end

      # Returns branch names collection that contains the special commit(SHA1
      # or name)
      #
      # Ex.
      #   repo.branch_names_contains('master')
      #
      def branch_names_contains(commit)
        branches_contains(commit).map { |c| c.name }
      end

      # Returns branch collection that contains the special commit(SHA1 or name)
      #
      # Ex.
      #   repo.branch_names_contains('master')
      #
      def branches_contains(commit)
        commit_obj = rugged.rev_parse(commit)
        parent = commit_obj.parents.first unless commit_obj.parents.empty?

        walker = Rugged::Walker.new(rugged)

        rugged.branches.select do |branch|
          walker.push(branch.target_id)
          walker.hide(parent) if parent
          result = walker.any? { |c| c.oid == commit_obj.oid }
          walker.reset

          result
        end
      end

      # Get refs hash which key is SHA1
      # and value is a Rugged::Reference
      def refs_hash
        # Initialize only when first call
        if @refs_hash.nil?
          @refs_hash = Hash.new { |h, k| h[k] = [] }

          rugged.references.each do |r|
            # Symbolic/remote references may not have an OID; skip over them
            target_oid = r.target.try(:oid)
            if target_oid
              sha = rev_parse_target(target_oid).oid
              @refs_hash[sha] << r
            end
          end
        end
        @refs_hash
      end

      # Lookup for rugged object by oid or ref name
      def lookup(oid_or_ref_name)
        rugged.rev_parse(oid_or_ref_name)
      end

      # Returns url for submodule
      #
      # Ex.
      #   @repository.submodule_url_for('master', 'rack')
      #   # => git@localhost:rack.git
      #
      # Gitaly migration: https://gitlab.com/gitlab-org/gitaly/issues/329
      def submodule_url_for(ref, path)
        Gitlab::GitalyClient.migrate(:submodule_url_for) do |is_enabled|
          if is_enabled
            gitaly_submodule_url_for(ref, path)
          else
            if submodules(ref).any?
              submodule = submodules(ref)[path]
              submodule['url'] if submodule
            end
          end
        end
      end

      # Return total commits count accessible from passed ref
      #
      # Gitaly migration: https://gitlab.com/gitlab-org/gitaly/issues/330
      def commit_count(ref)
        gitaly_migrate(:commit_count) do |is_enabled|
          if is_enabled
            gitaly_commit_client.commit_count(ref)
          else
            walker = Rugged::Walker.new(rugged)
            walker.sorting(Rugged::SORT_TOPO | Rugged::SORT_REVERSE)
            oid = rugged.rev_parse_oid(ref)
            walker.push(oid)
            walker.count
          end
        end
      end

      # Mimic the `git clean` command and recursively delete untracked files.
      # Valid keys that can be passed in the +options+ hash are:
      #
      # :d - Remove untracked directories
      # :f - Remove untracked directories that are managed by a different
      #      repository
      # :x - Remove ignored files
      #
      # The value in +options+ must evaluate to true for an option to take
      # effect.
      #
      # Examples:
      #
      #   repo.clean(d: true, f: true) # Enable the -d and -f options
      #
      #   repo.clean(d: false, x: true) # -x is enabled, -d is not
      def clean(options = {})
        strategies = [:remove_untracked]
        strategies.push(:force) if options[:f]
        strategies.push(:remove_ignored) if options[:x]

        # TODO: implement this method
      end

      # Delete the specified branch from the repository
      def delete_branch(branch_name)
        rugged.branches.delete(branch_name)
      end

      # Create a new branch named **ref+ based on **stat_point+, HEAD by default
      #
      # Examples:
      #   create_branch("feature")
      #   create_branch("other-feature", "master")
      def create_branch(ref, start_point = "HEAD")
        rugged_ref = rugged.branches.create(ref, start_point)
        target_commit = Gitlab::Git::Commit.find(self, rugged_ref.target)
        Gitlab::Git::Branch.new(self, rugged_ref.name, rugged_ref.target, target_commit)
      rescue Rugged::ReferenceError => e
        raise InvalidRef.new("Branch #{ref} already exists") if e.to_s =~ /'refs\/heads\/#{ref}'/
        raise InvalidRef.new("Invalid reference #{start_point}")
      end

      # Return an array of this repository's remote names
      def remote_names
        rugged.remotes.each_name.to_a
      end

      # Delete the specified remote from this repository.
      def remote_delete(remote_name)
        rugged.remotes.delete(remote_name)
      end

      # Add a new remote to this repository.  Returns a Rugged::Remote object
      def remote_add(remote_name, url)
        rugged.remotes.create(remote_name, url)
      end

      # Update the specified remote using the values in the +options+ hash
      #
      # Example
      # repo.update_remote("origin", url: "path/to/repo")
      def remote_update(remote_name, options = {})
        # TODO: Implement other remote options
        rugged.remotes.set_url(remote_name, options[:url]) if options[:url]
      end

      # Fetch the specified remote
      def fetch(remote_name)
        rugged.remotes[remote_name].fetch
      end

      # Push +*refspecs+ to the remote identified by +remote_name+.
      def push(remote_name, *refspecs)
        rugged.remotes[remote_name].push(refspecs)
      end

      AUTOCRLF_VALUES = {
        "true" => true,
        "false" => false,
        "input" => :input
      }.freeze

      def autocrlf
        AUTOCRLF_VALUES[rugged.config['core.autocrlf']]
      end

      def autocrlf=(value)
        rugged.config['core.autocrlf'] = AUTOCRLF_VALUES.invert[value]
      end

      # Returns result like "git ls-files" , recursive and full file path
      #
      # Ex.
      #   repo.ls_files('master')
      #
      # Gitaly migration: https://gitlab.com/gitlab-org/gitaly/issues/327
      def ls_files(ref)
        actual_ref = ref || root_ref

        begin
          sha_from_ref(actual_ref)
        rescue Rugged::OdbError, Rugged::InvalidError, Rugged::ReferenceError
          # Return an empty array if the ref wasn't found
          return []
        end

        cmd = %W(#{Gitlab.config.git.bin_path} --git-dir=#{path} ls-tree)
        cmd += %w(-r)
        cmd += %w(--full-tree)
        cmd += %w(--full-name)
        cmd += %W(-- #{actual_ref})

        raw_output = IO.popen(cmd, &:read).split("\n").map do |f|
          stuff, path = f.split("\t")
          _mode, type, _sha = stuff.split(" ")
          path if type == "blob"
          # Contain only blob type
        end

        raw_output.compact
      end

      # Gitaly migration: https://gitlab.com/gitlab-org/gitaly/issues/328
      def copy_gitattributes(ref)
        begin
          commit = lookup(ref)
        rescue Rugged::ReferenceError
          raise InvalidRef.new("Ref #{ref} is invalid")
        end

        # Create the paths
        info_dir_path = File.join(path, 'info')
        info_attributes_path = File.join(info_dir_path, 'attributes')

        begin
          # Retrieve the contents of the blob
          gitattributes_content = blob_content(commit, '.gitattributes')
        rescue InvalidBlobName
          # No .gitattributes found. Should now remove any info/attributes and return
          File.delete(info_attributes_path) if File.exist?(info_attributes_path)
          return
        end

        # Create the info directory if needed
        Dir.mkdir(info_dir_path) unless File.directory?(info_dir_path)

        # Write the contents of the .gitattributes file to info/attributes
        # Use binary mode to prevent Rails from converting ASCII-8BIT to UTF-8
        File.open(info_attributes_path, "wb") do |file|
          file.write(gitattributes_content)
        end
      end

      # Returns the Git attributes for the given file path.
      #
      # See `Gitlab::Git::Attributes` for more information.
      def attributes(path)
        @attributes.attributes(path)
      end

      def languages(ref = nil)
        Gitlab::GitalyClient.migrate(:commit_languages) do |is_enabled|
          if is_enabled
            gitaly_commit_client.languages(ref)
          else
            ref ||= rugged.head.target_id
            languages = Linguist::Repository.new(rugged, ref).languages
            total = languages.map(&:last).sum

            languages = languages.map do |language|
              name, share = language
              color = Linguist::Language[name].color || "##{Digest::SHA256.hexdigest(name)[0...6]}"
              {
                value: (share.to_f * 100 / total).round(2),
                label: name,
                color: color,
                highlight: color
              }
            end

            languages.sort do |x, y|
              y[:value] <=> x[:value]
            end
          end
        end
      end

      def gitaly_repository
        Gitlab::GitalyClient::Util.repository(@storage, @relative_path)
      end

      def gitaly_ref_client
        @gitaly_ref_client ||= Gitlab::GitalyClient::RefService.new(self)
      end

      def gitaly_commit_client
        @gitaly_commit_client ||= Gitlab::GitalyClient::CommitService.new(self)
      end

      def gitaly_repository_client
        @gitaly_repository_client ||= Gitlab::GitalyClient::RepositoryService.new(self)
      end

      def gitaly_migrate(method, &block)
        Gitlab::GitalyClient.migrate(method, &block)
      rescue GRPC::NotFound => e
        raise NoRepository.new(e)
      rescue GRPC::BadStatus => e
        raise CommandError.new(e)
      end

      private

      # Gitaly note: JV: Trying to get rid of the 'filter' option so we can implement this with 'git'.
      def branches_filter(filter: nil, sort_by: nil)
        branches = rugged.branches.each(filter).map do |rugged_ref|
          begin
            target_commit = Gitlab::Git::Commit.find(self, rugged_ref.target)
            Gitlab::Git::Branch.new(self, rugged_ref.name, rugged_ref.target, target_commit)
          rescue Rugged::ReferenceError
            # Omit invalid branch
          end
        end.compact

        sort_branches(branches, sort_by)
      end

      def raw_log(options)
        actual_ref = options[:ref] || root_ref
        begin
          sha = sha_from_ref(actual_ref)
        rescue Rugged::OdbError, Rugged::InvalidError, Rugged::ReferenceError
          # Return an empty array if the ref wasn't found
          return []
        end

        if log_using_shell?(options)
          log_by_shell(sha, options)
        else
          log_by_walk(sha, options)
        end
      end

      def log_using_shell?(options)
        options[:path].present? ||
          options[:disable_walk] ||
          options[:skip_merges] ||
          options[:after] ||
          options[:before]
      end

      def log_by_walk(sha, options)
        walk_options = {
          show: sha,
          sort: Rugged::SORT_NONE,
          limit: options[:limit],
          offset: options[:offset]
        }
        Rugged::Walker.walk(rugged, walk_options).to_a
      end

      # Gitaly note: JV: although #log_by_shell shells out to Git I think the
      # complexity is such that we should migrate it as Ruby before trying to
      # do it in Go.
      def log_by_shell(sha, options)
        limit = options[:limit].to_i
        offset = options[:offset].to_i
        use_follow_flag = options[:follow] && options[:path].present?

        # We will perform the offset in Ruby because --follow doesn't play well with --skip.
        # See: https://gitlab.com/gitlab-org/gitlab-ce/issues/3574#note_3040520
        offset_in_ruby = use_follow_flag && options[:offset].present?
        limit += offset if offset_in_ruby

        cmd = %W[#{Gitlab.config.git.bin_path} --git-dir=#{path} log]
        cmd << "--max-count=#{limit}"
        cmd << '--format=%H'
        cmd << "--skip=#{offset}" unless offset_in_ruby
        cmd << '--follow' if use_follow_flag
        cmd << '--no-merges' if options[:skip_merges]
        cmd << "--after=#{options[:after].iso8601}" if options[:after]
        cmd << "--before=#{options[:before].iso8601}" if options[:before]
        cmd << sha

        # :path can be a string or an array of strings
        if options[:path].present?
          cmd << '--'
          cmd += Array(options[:path])
        end

        raw_output = IO.popen(cmd) { |io| io.read }
        lines = offset_in_ruby ? raw_output.lines.drop(offset) : raw_output.lines

        lines.map! { |c| Rugged::Commit.new(rugged, c.strip) }
      end

      # We are trying to deprecate this method because it does a lot of work
      # but it seems to be used only to look up submodule URL's.
      # https://gitlab.com/gitlab-org/gitaly/issues/329
      def submodules(ref)
        commit = rev_parse_target(ref)
        return {} unless commit

        begin
          content = blob_content(commit, ".gitmodules")
        rescue InvalidBlobName
          return {}
        end

        parser = GitmodulesParser.new(content)
        fill_submodule_ids(commit, parser.parse)
      end

      def gitaly_submodule_url_for(ref, path)
        # We don't care about the contents so 1 byte is enough. Can't request 0 bytes, 0 means unlimited.
        commit_object = gitaly_commit_client.tree_entry(ref, path, 1)

        return unless commit_object && commit_object.type == :COMMIT

        gitmodules = gitaly_commit_client.tree_entry(ref, '.gitmodules', Gitlab::Git::Blob::MAX_DATA_DISPLAY_SIZE)
        return unless gitmodules

        found_module = GitmodulesParser.new(gitmodules.data).parse[path]

        found_module && found_module['url']
      end

      def alternate_object_directories
        Gitlab::Git::Env.all.values_at(*ALLOWED_OBJECT_DIRECTORIES_VARIABLES).compact
      end

      # Get the content of a blob for a given commit.  If the blob is a commit
      # (for submodules) then return the blob's OID.
      def blob_content(commit, blob_name)
        blob_entry = tree_entry(commit, blob_name)

        unless blob_entry
          raise InvalidBlobName.new("Invalid blob name: #{blob_name}")
        end

        case blob_entry[:type]
        when :commit
          blob_entry[:oid]
        when :tree
          raise InvalidBlobName.new("#{blob_name} is a tree, not a blob")
        when :blob
          rugged.lookup(blob_entry[:oid]).content
        end
      end

      # Fill in the 'id' field of a submodule hash from its values
      # as-of +commit+. Return a Hash consisting only of entries
      # from the submodule hash for which the 'id' field is filled.
      def fill_submodule_ids(commit, submodule_data)
        submodule_data.each do |path, data|
          id = begin
            blob_content(commit, path)
          rescue InvalidBlobName
            nil
          end
          data['id'] = id
        end
        submodule_data.select { |path, data| data['id'] }
      end

      # Find the entry for +path+ in the tree for +commit+
      def tree_entry(commit, path)
        pathname = Pathname.new(path)
        first = true
        tmp_entry = nil

        pathname.each_filename do |dir|
          if first
            tmp_entry = commit.tree[dir]
            first = false
          elsif tmp_entry.nil?
            return nil
          else
            begin
              tmp_entry = rugged.lookup(tmp_entry[:oid])
            rescue Rugged::OdbError, Rugged::InvalidError, Rugged::ReferenceError
              return nil
            end

            return nil unless tmp_entry.type == :tree
            tmp_entry = tmp_entry[dir]
          end
        end

        tmp_entry
      end

      # Return the Rugged patches for the diff between +from+ and +to+.
      def diff_patches(from, to, options = {}, *paths)
        options ||= {}
        break_rewrites = options[:break_rewrites]
        actual_options = Gitlab::Git::Diff.filter_diff_options(options.merge(paths: paths))

        diff = rugged.diff(from, to, actual_options)
        diff.find_similar!(break_rewrites: break_rewrites)
        diff.each_patch
      end

      def sort_branches(branches, sort_by)
        case sort_by
        when 'name'
          branches.sort_by(&:name)
        when 'updated_desc'
          branches.sort do |a, b|
            b.dereferenced_target.committed_date <=> a.dereferenced_target.committed_date
          end
        when 'updated_asc'
          branches.sort do |a, b|
            a.dereferenced_target.committed_date <=> b.dereferenced_target.committed_date
          end
        else
          branches
        end
      end

      def tags_from_rugged
        rugged.references.each("refs/tags/*").map do |ref|
          message = nil

          if ref.target.is_a?(Rugged::Tag::Annotation)
            tag_message = ref.target.message

            if tag_message.respond_to?(:chomp)
              message = tag_message.chomp
            end
          end

          target_commit = Gitlab::Git::Commit.find(self, ref.target)
          Gitlab::Git::Tag.new(self, ref.name, ref.target, target_commit, message)
        end.sort_by(&:name)
      end

      def last_commit_for_path_by_rugged(sha, path)
        sha = last_commit_id_for_path(sha, path)
        commit(sha)
      end

      def tags_from_gitaly
        gitaly_ref_client.tags
      end

      def size_by_shelling_out
        popen(%w(du -sk), path).first.strip.to_i
      end

      def size_by_gitaly
        gitaly_repository_client.repository_size
      end

      def count_commits_by_gitaly(options)
        gitaly_commit_client.commit_count(options[:ref], options)
      end

      def count_commits_by_shelling_out(options)
        cmd = %W[#{Gitlab.config.git.bin_path} --git-dir=#{path} rev-list]
        cmd << "--after=#{options[:after].iso8601}" if options[:after]
        cmd << "--before=#{options[:before].iso8601}" if options[:before]
        cmd += %W[--count #{options[:ref]}]
        cmd += %W[-- #{options[:path]}] if options[:path].present?

        raw_output = IO.popen(cmd) { |io| io.read }

        raw_output.to_i
      end
    end
  end
end
