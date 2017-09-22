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
      GitError = Class.new(StandardError)
      DeleteBranchError = Class.new(StandardError)
      CreateTreeError = Class.new(StandardError)

      class << self
        # Unlike `new`, `create` takes the storage path, not the storage name
        def create(storage_path, name, bare: true, symlink_hooks_to: nil)
          repo_path = File.join(storage_path, name)
          repo_path += '.git' unless repo_path.end_with?('.git')

          FileUtils.mkdir_p(repo_path, mode: 0770)

          # Equivalent to `git --git-path=#{repo_path} init [--bare]`
          repo = Rugged::Repository.init_at(repo_path, bare)
          repo.close

          if symlink_hooks_to.present?
            hooks_path = File.join(repo_path, 'hooks')
            FileUtils.rm_rf(hooks_path)
            FileUtils.ln_s(symlink_hooks_to, hooks_path)
          end

          true
        end
      end

      # Full path to repo
      attr_reader :path

      # Directory name of repo
      attr_reader :name

      # Relative path of repo
      attr_reader :relative_path

      # Rugged repo object
      attr_reader :rugged

      attr_reader :storage, :gl_repository, :relative_path

      # 'path' must be the path to a _bare_ git repository, e.g.
      # /path/to/my-repo.git
      def initialize(storage, relative_path, gl_repository)
        @storage = storage
        @relative_path = relative_path
        @gl_repository = gl_repository

        storage_path = Gitlab.config.repositories.storages[@storage]['path']
        @path = File.join(storage_path, @relative_path)
        @name = @relative_path.split("/").last
        @attributes = Gitlab::Git::Attributes.new(path)
      end

      delegate  :empty?,
                to: :rugged

      delegate :exists?, to: :gitaly_repository_client

      def ==(other)
        path == other.path
      end

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
        gitaly_migrate(:find_branch) do |is_enabled|
          if is_enabled
            gitaly_ref_client.find_branch(name)
          else
            reload_rugged if force_reload

            rugged_ref = rugged.branches[name]
            if rugged_ref
              target_commit = Gitlab::Git::Commit.find(self, rugged_ref.target)
              Gitlab::Git::Branch.new(self, rugged_ref.name, rugged_ref.target, target_commit)
            end
          end
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
            rugged.branches.each(:local).count do |ref|
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

      # Returns true if the given ref name exists
      #
      # Ref names must start with `refs/`.
      def ref_exists?(ref_name)
        gitaly_migrate(:ref_exists) do |is_enabled|
          if is_enabled
            gitaly_ref_exists?(ref_name)
          else
            rugged_ref_exists?(ref_name)
          end
        end
      end

      # Returns true if the given tag exists
      #
      # name - The name of the tag as a String.
      def tag_exists?(name)
        gitaly_migrate(:ref_exists_tags) do |is_enabled|
          if is_enabled
            gitaly_ref_exists?("refs/tags/#{name}")
          else
            rugged_tag_exists?(name)
          end
        end
      end

      # Returns true if the given branch exists
      #
      # name - The name of the branch as a String.
      def branch_exists?(name)
        gitaly_migrate(:ref_exists_branches) do |is_enabled|
          if is_enabled
            gitaly_ref_exists?("refs/heads/#{name}")
          else
            rugged_branch_exists?(name)
          end
        end
      end

      # Returns an Array of branch and tag names
      def ref_names
        branch_names + tag_names
      end

      def delete_all_refs_except(prefixes)
        delete_refs(*all_ref_names_except(prefixes))
      end

      # Returns an Array of all ref names, except when it's matching pattern
      #
      # regexp - The pattern for ref names we don't want
      def all_ref_names_except(prefixes)
        rugged.references.reject do |ref|
          prefixes.any? { |p| ref.name.start_with?(p) }
        end.map(&:name)
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

      # Used in gitaly-ruby
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
      def ancestor?(from, to)
        gitaly_commit_client.ancestor?(from, to)
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
            popen(args, @path).first.split.last
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

      def add_branch(branch_name, user:, target:)
        target_object = Ref.dereference_object(lookup(target))
        raise InvalidRef.new("target not found: #{target}") unless target_object

        OperationService.new(user, self).add_branch(branch_name, target_object.oid)
        find_branch(branch_name)
      rescue Rugged::ReferenceError => ex
        raise InvalidRef, ex
      end

      def add_tag(tag_name, user:, target:, message: nil)
        target_object = Ref.dereference_object(lookup(target))
        raise InvalidRef.new("target not found: #{target}") unless target_object

        user = Gitlab::Git::User.from_gitlab(user) unless user.respond_to?(:gl_id)

        options = nil # Use nil, not the empty hash. Rugged cares about this.
        if message
          options = {
            message: message,
            tagger: Gitlab::Git.committer_hash(email: user.email, name: user.name)
          }
        end

        OperationService.new(user, self).add_tag(tag_name, target_object.oid, options)

        find_tag(tag_name)
      rescue Rugged::ReferenceError => ex
        raise InvalidRef, ex
      end

      def rm_branch(branch_name, user:)
        OperationService.new(user, self).rm_branch(find_branch(branch_name))
      end

      def rm_tag(tag_name, user:)
        OperationService.new(user, self).rm_tag(find_tag(tag_name))
      end

      def find_tag(name)
        tags.find { |tag| tag.name == name }
      end

      def merge(user, source_sha, target_branch, message)
        committer = Gitlab::Git.committer_hash(email: user.email, name: user.name)

        OperationService.new(user, self).with_branch(target_branch) do |start_commit|
          our_commit = start_commit.sha
          their_commit = source_sha

          raise 'Invalid merge target' unless our_commit
          raise 'Invalid merge source' unless their_commit

          merge_index = rugged.merge_commits(our_commit, their_commit)
          break if merge_index.conflicts?

          options = {
            parents: [our_commit, their_commit],
            tree: merge_index.write_tree(rugged),
            message: message,
            author: committer,
            committer: committer
          }

          commit_id = create_commit(options)

          yield commit_id

          commit_id
        end
      rescue Gitlab::Git::CommitError # when merge_index.conflicts?
        nil
      end

      def revert(user:, commit:, branch_name:, message:, start_branch_name:, start_repository:)
        OperationService.new(user, self).with_branch(
          branch_name,
          start_branch_name: start_branch_name,
          start_repository: start_repository
        ) do |start_commit|

          Gitlab::Git.check_namespace!(commit, start_repository)

          revert_tree_id = check_revert_content(commit, start_commit.sha)
          raise CreateTreeError unless revert_tree_id

          committer = user_to_committer(user)

          create_commit(message: message,
                        author: committer,
                        committer: committer,
                        tree: revert_tree_id,
                        parents: [start_commit.sha])
        end
      end

      def check_revert_content(target_commit, source_sha)
        args = [target_commit.sha, source_sha]
        args << { mainline: 1 } if target_commit.merge_commit?

        revert_index = rugged.revert_commit(*args)
        return false if revert_index.conflicts?

        tree_id = revert_index.write_tree(rugged)
        return false unless diff_exists?(source_sha, tree_id)

        tree_id
      end

      def cherry_pick(user:, commit:, branch_name:, message:, start_branch_name:, start_repository:)
        OperationService.new(user, self).with_branch(
          branch_name,
          start_branch_name: start_branch_name,
          start_repository: start_repository
        ) do |start_commit|

          Gitlab::Git.check_namespace!(commit, start_repository)

          cherry_pick_tree_id = check_cherry_pick_content(commit, start_commit.sha)
          raise CreateTreeError unless cherry_pick_tree_id

          committer = user_to_committer(user)

          create_commit(message: message,
                        author: {
                            email: commit.author_email,
                            name: commit.author_name,
                            time: commit.authored_date
                        },
                        committer: committer,
                        tree: cherry_pick_tree_id,
                        parents: [start_commit.sha])
        end
      end

      def check_cherry_pick_content(target_commit, source_sha)
        args = [target_commit.sha, source_sha]
        args << 1 if target_commit.merge_commit?

        cherry_pick_index = rugged.cherrypick_commit(*args)
        return false if cherry_pick_index.conflicts?

        tree_id = cherry_pick_index.write_tree(rugged)
        return false unless diff_exists?(source_sha, tree_id)

        tree_id
      end

      def diff_exists?(sha1, sha2)
        rugged.diff(sha1, sha2).size > 0
      end

      def user_to_committer(user)
        Gitlab::Git.committer_hash(email: user.email, name: user.name)
      end

      def create_commit(params = {})
        params[:message].delete!("\r")

        Rugged::Commit.create(rugged, params)
      end

      # Delete the specified branch from the repository
      def delete_branch(branch_name)
        gitaly_migrate(:delete_branch) do |is_enabled|
          if is_enabled
            gitaly_ref_client.delete_branch(branch_name)
          else
            rugged.branches.delete(branch_name)
          end
        end
      rescue Rugged::ReferenceError, CommandError => e
        raise DeleteBranchError, e
      end

      def delete_refs(*ref_names)
        instructions = ref_names.map do |ref|
          "delete #{ref}\x00\x00"
        end

        command = %W[#{Gitlab.config.git.bin_path} update-ref --stdin -z]
        message, status = popen(command, path) do |stdin|
          stdin.write(instructions.join)
        end

        unless status.zero?
          raise GitError.new("Could not delete refs #{ref_names}: #{message}")
        end
      end

      # Create a new branch named **ref+ based on **stat_point+, HEAD by default
      #
      # Examples:
      #   create_branch("feature")
      #   create_branch("other-feature", "master")
      def create_branch(ref, start_point = "HEAD")
        gitaly_migrate(:create_branch) do |is_enabled|
          if is_enabled
            gitaly_ref_client.create_branch(ref, start_point)
          else
            rugged_create_branch(ref, start_point)
          end
        end
      end

      # Delete the specified remote from this repository.
      def remote_delete(remote_name)
        rugged.remotes.delete(remote_name)
        nil
      end

      # Add a new remote to this repository.
      def remote_add(remote_name, url)
        rugged.remotes.create(remote_name, url)
        nil
      end

      # Update the specified remote using the values in the +options+ hash
      #
      # Example
      # repo.update_remote("origin", url: "path/to/repo")
      def remote_update(remote_name, url:)
        # TODO: Implement other remote options
        rugged.remotes.set_url(remote_name, url)
        nil
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
        gitaly_migrate(:ls_files) do |is_enabled|
          if is_enabled
            gitaly_ls_files(ref)
          else
            git_ls_files(ref)
          end
        end
      end

      # Gitaly migration: https://gitlab.com/gitlab-org/gitaly/issues/328
      def copy_gitattributes(ref)
        Gitlab::GitalyClient.migrate(:apply_gitattributes) do |is_enabled|
          if is_enabled
            gitaly_copy_gitattributes(ref)
          else
            rugged_copy_gitattributes(ref)
          end
        end
      rescue GRPC::InvalidArgument
        raise InvalidRef
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

      def with_repo_branch_commit(start_repository, start_branch_name)
        Gitlab::Git.check_namespace!(start_repository)

        return yield nil if start_repository.empty_repo?

        if start_repository == self
          yield commit(start_branch_name)
        else
          sha = start_repository.commit(start_branch_name).sha

          if branch_commit = commit(sha)
            yield branch_commit
          else
            with_repo_tmp_commit(
              start_repository, start_branch_name, sha) do |tmp_commit|
              yield tmp_commit
            end
          end
        end
      end

      def with_repo_tmp_commit(start_repository, start_branch_name, sha)
        tmp_ref = fetch_ref(
          start_repository.path,
          "#{Gitlab::Git::BRANCH_REF_PREFIX}#{start_branch_name}",
          "refs/tmp/#{SecureRandom.hex}/head"
        )

        yield commit(sha)
      ensure
        delete_refs(tmp_ref) if tmp_ref
      end

      def fetch_source_branch(source_repository, source_branch, local_ref)
        with_repo_branch_commit(source_repository, source_branch) do |commit|
          if commit
            write_ref(local_ref, commit.sha)
          else
            raise Rugged::ReferenceError, 'source repository is empty'
          end
        end
      end

      def compare_source_branch(target_branch_name, source_repository, source_branch_name, straight:)
        with_repo_branch_commit(source_repository, source_branch_name) do |commit|
          break unless commit

          Gitlab::Git::Compare.new(
            self,
            target_branch_name,
            commit.sha,
            straight: straight
          )
        end
      end

      def write_ref(ref_path, sha)
        rugged.references.create(ref_path, sha, force: true)
      end

      def fetch_ref(source_path, source_ref, target_ref)
        args = %W(fetch --no-tags -f #{source_path} #{source_ref}:#{target_ref})
        message, status = run_git(args)

        # Make sure ref was created, and raise Rugged::ReferenceError when not
        raise Rugged::ReferenceError, message if status != 0

        target_ref
      end

      # Refactoring aid; allows us to copy code from app/models/repository.rb
      def run_git(args)
        circuit_breaker.perform do
          popen([Gitlab.config.git.bin_path, *args], path)
        end
      end

      # Refactoring aid; allows us to copy code from app/models/repository.rb
      def commit(ref = 'HEAD')
        Gitlab::Git::Commit.find(self, ref)
      end

      # Refactoring aid; allows us to copy code from app/models/repository.rb
      def empty_repo?
        !exists? || !has_visible_content?
      end

      #
      # Git repository can contains some hidden refs like:
      #   /refs/notes/*
      #   /refs/git-as-svn/*
      #   /refs/pulls/*
      # This refs by default not visible in project page and not cloned to client side.
      #
      # This method return true if repository contains some content visible in project page.
      #
      def has_visible_content?
        branch_count > 0
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

      def gitaly_migrate(method, status: Gitlab::GitalyClient::MigrationStatus::OPT_IN, &block)
        Gitlab::GitalyClient.migrate(method, status: status, &block)
      rescue GRPC::NotFound => e
        raise NoRepository.new(e)
      rescue GRPC::BadStatus => e
        raise CommandError.new(e)
      end

      private

      # Gitaly note: JV: Trying to get rid of the 'filter' option so we can implement this with 'git'.
      def branches_filter(filter: nil, sort_by: nil)
        # n+1: https://gitlab.com/gitlab-org/gitlab-ce/issues/37464
        branches = Gitlab::GitalyClient.allow_n_plus_1_calls do
          rugged.branches.each(filter).map do |rugged_ref|
            begin
              target_commit = Gitlab::Git::Commit.find(self, rugged_ref.target)
              Gitlab::Git::Branch.new(self, rugged_ref.name, rugged_ref.target, target_commit)
            rescue Rugged::ReferenceError
              # Omit invalid branch
            end
          end.compact
        end

        sort_branches(branches, sort_by)
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

      def gitaly_ls_files(ref)
        gitaly_commit_client.ls_files(ref)
      end

      def git_ls_files(ref)
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

      # Returns true if the given ref name exists
      #
      # Ref names must start with `refs/`.
      def rugged_ref_exists?(ref_name)
        raise ArgumentError, 'invalid refname' unless ref_name.start_with?('refs/')
        rugged.references.exist?(ref_name)
      rescue Rugged::ReferenceError
        false
      end

      # Returns true if the given ref name exists
      #
      # Ref names must start with `refs/`.
      def gitaly_ref_exists?(ref_name)
        gitaly_ref_client.ref_exists?(ref_name)
      end

      # Returns true if the given tag exists
      #
      # name - The name of the tag as a String.
      def rugged_tag_exists?(name)
        !!rugged.tags[name]
      end

      # Returns true if the given branch exists
      #
      # name - The name of the branch as a String.
      def rugged_branch_exists?(name)
        rugged.branches.exists?(name)

      # If the branch name is invalid (e.g. ".foo") Rugged will raise an error.
      # Whatever code calls this method shouldn't have to deal with that so
      # instead we just return `false` (which is true since a branch doesn't
      # exist when it has an invalid name).
      rescue Rugged::ReferenceError
        false
      end

      def rugged_create_branch(ref, start_point)
        rugged_ref = rugged.branches.create(ref, start_point)
        target_commit = Gitlab::Git::Commit.find(self, rugged_ref.target)
        Gitlab::Git::Branch.new(self, rugged_ref.name, rugged_ref.target, target_commit)
      rescue Rugged::ReferenceError => e
        raise InvalidRef.new("Branch #{ref} already exists") if e.to_s =~ /'refs\/heads\/#{ref}'/
        raise InvalidRef.new("Invalid reference #{start_point}")
      end

      def gitaly_copy_gitattributes(revision)
        gitaly_repository_client.apply_gitattributes(revision)
      end

      def rugged_copy_gitattributes(ref)
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
    end
  end
end
