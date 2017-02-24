# Gitlab::Git::Repository is a wrapper around native Rugged::Repository object
require 'tempfile'
require 'forwardable'
require "rubygems/package"

module Gitlab
  module Git
    class Repository
      include Gitlab::Git::Popen

      SEARCH_CONTEXT_LINES = 3

      class NoRepository < StandardError; end
      class InvalidBlobName < StandardError; end
      class InvalidRef < StandardError; end

      # Full path to repo
      attr_reader :path

      # Directory name of repo
      attr_reader :name

      # Rugged repo object
      attr_reader :rugged

      # 'path' must be the path to a _bare_ git repository, e.g.
      # /path/to/my-repo.git
      def initialize(path)
        @path = path
        @name = path.split("/").last
        @attributes = Gitlab::Git::Attributes.new(path)
      end

      delegate  :empty?,
                :bare?,
                to: :rugged

      # Default branch in the repository
      def root_ref
        @root_ref ||= discover_default_branch
      end

      # Alias to old method for compatibility
      def raw
        rugged
      end

      def rugged
        @rugged ||= Rugged::Repository.new(path)
      rescue Rugged::RepositoryError, Rugged::OSError
        raise NoRepository.new('no repository for such path')
      end

      # Returns an Array of branch names
      # sorted by name ASC
      def branch_names
        branches.map(&:name)
      end

      # Returns an Array of Branches
      def branches
        rugged.branches.map do |rugged_ref|
          begin
            Gitlab::Git::Branch.new(self, rugged_ref.name, rugged_ref.target)
          rescue Rugged::ReferenceError
            # Omit invalid branch
          end
        end.compact.sort_by(&:name)
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
        Gitlab::Git::Branch.new(self, rugged_ref.name, rugged_ref.target) if rugged_ref
      end

      def local_branches
        rugged.branches.each(:local).map do |branch|
          Gitlab::Git::Branch.new(self, branch.name, branch.target)
        end
      end

      # Returns the number of valid branches
      def branch_count
        rugged.branches.count do |ref|
          begin
            ref.name && ref.target # ensures the branch is valid

            true
          rescue Rugged::ReferenceError
            false
          end
        end
      end

      # Returns an Array of tag names
      def tag_names
        rugged.tags.map { |t| t.name }
      end

      # Returns an Array of Tags
      def tags
        rugged.references.each("refs/tags/*").map do |ref|
          message = nil

          if ref.target.is_a?(Rugged::Tag::Annotation)
            tag_message = ref.target.message

            if tag_message.respond_to?(:chomp)
              message = tag_message.chomp
            end
          end

          Gitlab::Git::Tag.new(self, ref.name, ref.target, message)
        end.sort_by(&:name)
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

      # Deprecated. Will be removed in 5.2
      def heads
        rugged.references.each("refs/heads/*").map do |head|
          Gitlab::Git::Ref.new(self, head.name, head.target)
        end.sort_by(&:name)
      end

      def has_commits?
        !empty?
      end

      def repo_exists?
        !!rugged
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

      def archive_metadata(ref, storage_path, format = "tar.gz")
        ref ||= root_ref
        commit = Gitlab::Git::Commit.find(self, ref)
        return {} if commit.nil?

        project_name = self.name.chomp('.git')
        prefix = "#{project_name}-#{ref}-#{commit.id}"

        {
          'RepoPath' => path,
          'ArchivePrefix' => prefix,
          'ArchivePath' => archive_file_path(prefix, storage_path, format),
          'CommitId' => commit.id,
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
        size = popen(%w(du -sk), path).first.strip.to_i
        (size.to_f / 1024).round(2)
      end

      # Returns an array of BlobSnippets for files at the specified +ref+ that
      # contain the +query+ string.
      def search_files(query, ref = nil)
        greps = []
        ref ||= root_ref

        populated_index(ref).each do |entry|
          # Discard submodules
          next if submodule?(entry)

          blob = Gitlab::Git::Blob.raw(self, entry[:oid])

          # Skip binary files
          next if blob.data.encoding == Encoding::ASCII_8BIT

          blob.load_all_data!(self)
          greps += build_greps(blob.data, query, ref, entry[:path])
        end

        greps
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
          sort: Rugged::SORT_DATE,
          limit: options[:limit],
          offset: options[:offset]
        }
        Rugged::Walker.walk(rugged, walk_options).to_a
      end

      def log_by_shell(sha, options)
        cmd = %W(#{Gitlab.config.git.bin_path} --git-dir=#{path} log)
        cmd += %W(-n #{options[:limit].to_i})
        cmd += %w(--format=%H)
        cmd += %W(--skip=#{options[:offset].to_i})
        cmd += %w(--follow) if options[:follow]
        cmd += %w(--no-merges) if options[:skip_merges]
        cmd += %W(--after=#{options[:after].iso8601}) if options[:after]
        cmd += %W(--before=#{options[:before].iso8601}) if options[:before]
        cmd += [sha]
        cmd += %W(-- #{options[:path]}) if options[:path].present?

        raw_output = IO.popen(cmd) {|io| io.read }

        log = raw_output.lines.map do |c|
          Rugged::Commit.new(rugged, c.strip)
        end

        log.is_a?(Array) ? log : []
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
      def commits_between(from, to)
        walker = Rugged::Walker.new(rugged)
        walker.sorting(Rugged::SORT_DATE | Rugged::SORT_REVERSE)

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
        commits_between(from, to).size
      end

      # Returns the SHA of the most recent common ancestor of +from+ and +to+
      def merge_base_commit(from, to)
        rugged.merge_base(from, to)
      end

      # Return an array of Diff objects that represent the diff
      # between +from+ and +to+.  See Diff::filter_diff_options for the allowed
      # diff options.  The +options+ hash can also include :break_rewrites to
      # split larger rewrites into delete/add pairs.
      def diff(from, to, options = {}, *paths)
        Gitlab::Git::DiffCollection.new(diff_patches(from, to, options, *paths), options)
      end

      # Returns commits collection
      #
      # Ex.
      #   repo.find_commits(
      #     ref: 'master',
      #     max_count: 10,
      #     skip: 5,
      #     order: :date
      #   )
      #
      #   +options+ is a Hash of optional arguments to git
      #     :ref is the ref from which to begin (SHA1 or name)
      #     :contains is the commit contained by the refs from which to begin (SHA1 or name)
      #     :max_count is the maximum number of commits to fetch
      #     :skip is the number of commits to skip
      #     :order is the commits order and allowed value is :date(default) or :topo
      #
      def find_commits(options = {})
        actual_options = options.dup

        allowed_options = [:ref, :max_count, :skip, :contains, :order]

        actual_options.keep_if do |key|
          allowed_options.include?(key)
        end

        default_options = { skip: 0 }
        actual_options = default_options.merge(actual_options)

        walker = Rugged::Walker.new(rugged)

        if actual_options[:ref]
          walker.push(rugged.rev_parse_oid(actual_options[:ref]))
        elsif actual_options[:contains]
          branches_contains(actual_options[:contains]).each do |branch|
            walker.push(branch.target_id)
          end
        else
          rugged.references.each("refs/heads/*") do |ref|
            walker.push(ref.target_id)
          end
        end

        if actual_options[:order] == :topo
          walker.sorting(Rugged::SORT_TOPO)
        else
          walker.sorting(Rugged::SORT_DATE)
        end

        commits = []
        offset = actual_options[:skip]
        limit = actual_options[:max_count]
        walker.each(offset: offset, limit: limit) do |commit|
          gitlab_commit = Gitlab::Git::Commit.decorate(commit)
          commits.push(gitlab_commit)
        end

        walker.reset

        commits
      rescue Rugged::OdbError
        []
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

      # Return hash with submodules info for this repository
      #
      # Ex.
      #   {
      #     "rack"  => {
      #       "id" => "c67be4624545b4263184c4a0e8f887efd0a66320",
      #       "path" => "rack",
      #       "url" => "git://github.com/chneukirchen/rack.git"
      #     },
      #     "encoding" => {
      #       "id" => ....
      #     }
      #   }
      #
      def submodules(ref)
        commit = rev_parse_target(ref)
        return {} unless commit

        begin
          content = blob_content(commit, ".gitmodules")
        rescue InvalidBlobName
          return {}
        end

        parse_gitmodules(commit, content)
      end

      # Return total commits count accessible from passed ref
      def commit_count(ref)
        walker = Rugged::Walker.new(rugged)
        walker.sorting(Rugged::SORT_TOPO | Rugged::SORT_REVERSE)
        oid = rugged.rev_parse_oid(ref)
        walker.push(oid)
        walker.count
      end

      # Sets HEAD to the commit specified by +ref+; +ref+ can be a branch or
      # tag name or a commit SHA.  Valid +reset_type+ values are:
      #
      #  [:soft]
      #    the head will be moved to the commit.
      #  [:mixed]
      #    will trigger a +:soft+ reset, plus the index will be replaced
      #    with the content of the commit tree.
      #  [:hard]
      #    will trigger a +:mixed+ reset and the working directory will be
      #    replaced with the content of the index. (Untracked and ignored files
      #    will be left alone)
      delegate :reset, to: :rugged

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

      # Check out the specified ref. Valid options are:
      #
      #  :b - Create a new branch at +start_point+ and set HEAD to the new
      #       branch.
      #
      #  * These options are passed to the Rugged::Repository#checkout method:
      #
      #  :progress ::
      #    A callback that will be executed for checkout progress notifications.
      #    Up to 3 parameters are passed on each execution:
      #
      #    - The path to the last updated file (or +nil+ on the very first
      #      invocation).
      #    - The number of completed checkout steps.
      #    - The number of total checkout steps to be performed.
      #
      #  :notify ::
      #    A callback that will be executed for each checkout notification
      #    types specified with +:notify_flags+. Up to 5 parameters are passed
      #    on each execution:
      #
      #    - An array containing the +:notify_flags+ that caused the callback
      #      execution.
      #    - The path of the current file.
      #    - A hash describing the baseline blob (or +nil+ if it does not
      #      exist).
      #    - A hash describing the target blob (or +nil+ if it does not exist).
      #    - A hash describing the workdir blob (or +nil+ if it does not
      #      exist).
      #
      #  :strategy ::
      #    A single symbol or an array of symbols representing the strategies
      #    to use when performing the checkout. Possible values are:
      #
      #    :none ::
      #      Perform a dry run (default).
      #
      #    :safe ::
      #      Allow safe updates that cannot overwrite uncommitted data.
      #
      #    :safe_create ::
      #      Allow safe updates plus creation of missing files.
      #
      #    :force ::
      #      Allow all updates to force working directory to look like index.
      #
      #    :allow_conflicts ::
      #      Allow checkout to make safe updates even if conflicts are found.
      #
      #    :remove_untracked ::
      #      Remove untracked files not in index (that are not ignored).
      #
      #    :remove_ignored ::
      #      Remove ignored files not in index.
      #
      #    :update_only ::
      #      Only update existing files, don't create new ones.
      #
      #    :dont_update_index ::
      #      Normally checkout updates index entries as it goes; this stops
      #      that.
      #
      #    :no_refresh ::
      #      Don't refresh index/config/etc before doing checkout.
      #
      #    :disable_pathspec_match ::
      #      Treat pathspec as simple list of exact match file paths.
      #
      #    :skip_locked_directories ::
      #      Ignore directories in use, they will be left empty.
      #
      #    :skip_unmerged ::
      #      Allow checkout to skip unmerged files (NOT IMPLEMENTED).
      #
      #    :use_ours ::
      #      For unmerged files, checkout stage 2 from index (NOT IMPLEMENTED).
      #
      #    :use_theirs ::
      #      For unmerged files, checkout stage 3 from index (NOT IMPLEMENTED).
      #
      #    :update_submodules ::
      #      Recursively checkout submodules with same options (NOT
      #      IMPLEMENTED).
      #
      #    :update_submodules_if_changed ::
      #      Recursively checkout submodules if HEAD moved in super repo (NOT
      #      IMPLEMENTED).
      #
      #  :disable_filters ::
      #    If +true+, filters like CRLF line conversion will be disabled.
      #
      #  :dir_mode ::
      #    Mode for newly created directories. Default: +0755+.
      #
      #  :file_mode ::
      #    Mode for newly created files. Default: +0755+ or +0644+.
      #
      #  :file_open_flags ::
      #    Mode for opening files. Default:
      #    <code>IO::CREAT | IO::TRUNC | IO::WRONLY</code>.
      #
      #  :notify_flags ::
      #    A single symbol or an array of symbols representing the cases in
      #    which the +:notify+ callback should be invoked. Possible values are:
      #
      #    :none ::
      #      Do not invoke the +:notify+ callback (default).
      #
      #    :conflict ::
      #      Invoke the callback for conflicting paths.
      #
      #    :dirty ::
      #      Invoke the callback for "dirty" files, i.e. those that do not need
      #      an update but no longer match the baseline.
      #
      #    :updated ::
      #      Invoke the callback for any file that was changed.
      #
      #    :untracked ::
      #      Invoke the callback for untracked files.
      #
      #    :ignored ::
      #      Invoke the callback for ignored files.
      #
      #    :all ::
      #      Invoke the callback for all these cases.
      #
      #  :paths ::
      #    A glob string or an array of glob strings specifying which paths
      #    should be taken into account for the checkout operation. +nil+ will
      #    match all files.  Default: +nil+.
      #
      #  :baseline ::
      #    A Rugged::Tree that represents the current, expected contents of the
      #    workdir.  Default: +HEAD+.
      #
      #  :target_directory ::
      #    A path to an alternative workdir directory in which the checkout
      #    should be performed.
      def checkout(ref, options = {}, start_point = "HEAD")
        if options[:b]
          rugged.branches.create(ref, start_point)
          options.delete(:b)
        end
        default_options = { strategy: [:recreate_missing, :safe] }
        rugged.checkout(ref, default_options.merge(options))
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
        Gitlab::Git::Branch.new(self, rugged_ref.name, rugged_ref.target)
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

      # Merge the +source_name+ branch into the +target_name+ branch. This is
      # equivalent to `git merge --no_ff +source_name+`, since a merge commit
      # is always created.
      def merge(source_name, target_name, options = {})
        our_commit = rugged.branches[target_name].target
        their_commit = rugged.branches[source_name].target

        raise "Invalid merge target" if our_commit.nil?
        raise "Invalid merge source" if their_commit.nil?

        merge_index = rugged.merge_commits(our_commit, their_commit)
        return false if merge_index.conflicts?

        actual_options = options.merge(
          parents: [our_commit, their_commit],
          tree: merge_index.write_tree(rugged),
          update_ref: "refs/heads/#{target_name}"
        )
        Rugged::Commit.create(rugged, actual_options)
      end

      def commits_since(from_date)
        walker = Rugged::Walker.new(rugged)
        walker.sorting(Rugged::SORT_DATE | Rugged::SORT_REVERSE)

        rugged.references.each("refs/heads/*") do |ref|
          walker.push(ref.target_id)
        end

        commits = []
        walker.each do |commit|
          break if commit.author[:time].to_date < from_date
          commits.push(commit)
        end

        commits
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

      # Create a new directory with a .gitkeep file. Creates
      # all required nested directories (i.e. mkdir -p behavior)
      #
      # options should contain next structure:
      #   author: {
      #     email: 'user@example.com',
      #     name: 'Test User',
      #     time: Time.now
      #   },
      #   committer: {
      #     email: 'user@example.com',
      #     name: 'Test User',
      #     time: Time.now
      #   },
      #   commit: {
      #     message: 'Wow such commit',
      #     branch: 'master',
      #     update_ref: false
      #   }
      def mkdir(path, options = {})
        # Check if this directory exists; if it does, then don't bother
        # adding .gitkeep file.
        ref = options[:commit][:branch]
        path = Gitlab::Git::PathHelper.normalize_path(path).to_s
        rugged_ref = rugged.ref(ref)

        raise InvalidRef.new("Invalid ref") if rugged_ref.nil?

        target_commit = rugged_ref.target

        raise InvalidRef.new("Invalid target commit") if target_commit.nil?

        entry = tree_entry(target_commit, path)

        if entry
          if entry[:type] == :blob
            raise InvalidBlobName.new("Directory already exists as a file")
          else
            raise InvalidBlobName.new("Directory already exists")
          end
        end

        options[:file] = {
          content: '',
          path: "#{path}/.gitkeep",
          update: true
        }

        Gitlab::Git::Blob.commit(self, options)
      end

      # Returns result like "git ls-files" , recursive and full file path
      #
      # Ex.
      #   repo.ls_files('master')
      #
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

      # Checks if the blob should be diffable according to its attributes
      def diffable?(blob)
        attributes(blob.path).fetch('diff') { blob.text? }
      end

      # Returns the Git attributes for the given file path.
      #
      # See `Gitlab::Git::Attributes` for more information.
      def attributes(path)
        @attributes.attributes(path)
      end

      private

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

      # Parses the contents of a .gitmodules file and returns a hash of
      # submodule information.
      def parse_gitmodules(commit, content)
        results = {}

        current = ""
        content.split("\n").each do |txt|
          if txt =~ /^\s*\[/
            current = txt.match(/(?<=").*(?=")/)[0]
            results[current] = {}
          else
            next unless results[current]
            match_data = txt.match(/(\w+)\s*=\s*(.*)/)
            next unless match_data
            target = match_data[2].chomp
            results[current][match_data[1]] = target

            if match_data[1] == "path"
              begin
                results[current]["id"] = blob_content(commit, target)
              rescue InvalidBlobName
                results.delete(current)
              end
            end
          end
        end

        results
      end

      # Returns true if +commit+ introduced changes to +path+, using commit
      # trees to make that determination.  Uses the history simplification
      # rules that `git log` uses by default, where a commit is omitted if it
      # is TREESAME to any parent.
      #
      # If the +follow+ option is true and the file specified by +path+ was
      # renamed, then the path value is set to the old path.
      def commit_touches_path?(commit, path, follow, walker)
        entry = tree_entry(commit, path)

        if commit.parents.empty?
          # This is the root commit, return true if it has +path+ in its tree
          return !entry.nil?
        end

        num_treesame = 0
        commit.parents.each do |parent|
          parent_entry = tree_entry(parent, path)

          # Only follow the first TREESAME parent for merge commits
          if num_treesame > 0
            walker.hide(parent)
            next
          end

          if entry.nil? && parent_entry.nil?
            num_treesame += 1
          elsif entry && parent_entry && entry[:oid] == parent_entry[:oid]
            num_treesame += 1
          end
        end

        case num_treesame
        when 0
          detect_rename(commit, commit.parents.first, path) if follow
          true
        else false
        end
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
            tmp_entry = rugged.lookup(tmp_entry[:oid])
            return nil unless tmp_entry.type == :tree
            tmp_entry = tmp_entry[dir]
          end
        end

        tmp_entry
      end

      # Compare +commit+ and +parent+ for +path+.  If +path+ is a file and was
      # renamed in +commit+, then set +path+ to the old filename.
      def detect_rename(commit, parent, path)
        diff = parent.diff(commit, paths: [path], disable_pathspec_match: true)

        # If +path+ is a filename, not a directory, then we should only have
        # one delta.  We don't need to follow renames for directories.
        return nil if diff.each_delta.count > 1

        delta = diff.each_delta.first
        if delta.added?
          full_diff = parent.diff(commit)
          full_diff.find_similar!

          full_diff.each_delta do |full_delta|
            if full_delta.renamed? && path == full_delta.new_file[:path]
              # Look for the old path in ancestors
              path.replace(full_delta.old_file[:path])
            end
          end
        end
      end

      def archive_to_file(treeish = 'master', filename = 'archive.tar.gz', format = nil, compress_cmd = %w(gzip -n))
        git_archive_cmd = %W(#{Gitlab.config.git.bin_path} --git-dir=#{path} archive)

        # Put files into a directory before archiving
        prefix = "#{archive_name(treeish)}/"
        git_archive_cmd << "--prefix=#{prefix}"

        # Format defaults to tar
        git_archive_cmd << "--format=#{format}" if format

        git_archive_cmd += %W(-- #{treeish})

        open(filename, 'w') do |file|
          # Create a pipe to act as the '|' in 'git archive ... | gzip'
          pipe_rd, pipe_wr = IO.pipe

          # Get the compression process ready to accept data from the read end
          # of the pipe
          compress_pid = spawn(*nice(compress_cmd), in: pipe_rd, out: file)
          # The read end belongs to the compression process now; we should
          # close our file descriptor for it.
          pipe_rd.close

          # Start 'git archive' and tell it to write into the write end of the
          # pipe.
          git_archive_pid = spawn(*nice(git_archive_cmd), out: pipe_wr)
          # The write end belongs to 'git archive' now; close it.
          pipe_wr.close

          # When 'git archive' and the compression process are finished, we are
          # done.
          Process.waitpid(git_archive_pid)
          raise "#{git_archive_cmd.join(' ')} failed" unless $?.success?
          Process.waitpid(compress_pid)
          raise "#{compress_cmd.join(' ')} failed" unless $?.success?
        end
      end

      def nice(cmd)
        nice_cmd = %w(nice -n 20)
        unless unsupported_platform?
          nice_cmd += %w(ionice -c 2 -n 7)
        end
        nice_cmd + cmd
      end

      def unsupported_platform?
        %w[darwin freebsd solaris].map { |platform| RUBY_PLATFORM.include?(platform) }.any?
      end

      # Returns true if the index entry has the special file mode that denotes
      # a submodule.
      def submodule?(index_entry)
        index_entry[:mode] == 57344
      end

      # Return a Rugged::Index that has read from the tree at +ref_name+
      def populated_index(ref_name)
        commit = rev_parse_target(ref_name)
        index = rugged.index
        index.read_tree(commit.tree)
        index
      end

      # Return an array of BlobSnippets for lines in +file_contents+ that match
      # +query+
      def build_greps(file_contents, query, ref, filename)
        # The file_contents string is potentially huge so we make sure to loop
        # through it one line at a time. This gives Ruby the chance to GC lines
        # we are not interested in.
        #
        # We need to do a little extra work because we are not looking for just
        # the lines that matches the query, but also for the context
        # (surrounding lines). We will use Enumerable#each_cons to efficiently
        # loop through the lines while keeping surrounding lines on hand.
        #
        # First, we turn "foo\nbar\nbaz" into
        # [
        #  [nil, -3], [nil, -2], [nil, -1],
        #  ['foo', 0], ['bar', 1], ['baz', 3],
        #  [nil, 4], [nil, 5], [nil, 6]
        # ]
        lines_with_index = Enumerator.new do |yielder|
          # Yield fake 'before' lines for the first line of file_contents
          (-SEARCH_CONTEXT_LINES..-1).each do |i|
            yielder.yield [nil, i]
          end

          # Yield the actual file contents
          count = 0
          file_contents.each_line do |line|
            line.chomp!
            yielder.yield [line, count]
            count += 1
          end

          # Yield fake 'after' lines for the last line of file_contents
          (count + 1..count + SEARCH_CONTEXT_LINES).each do |i|
            yielder.yield [nil, i]
          end
        end

        greps = []

        # Loop through consecutive blocks of lines with indexes
        lines_with_index.each_cons(2 * SEARCH_CONTEXT_LINES + 1) do |line_block|
          # Get the 'middle' line and index from the block
          line, _ = line_block[SEARCH_CONTEXT_LINES]

          next unless line && line.match(/#{Regexp.escape(query)}/i)

          # Yay, 'line' contains a match!
          # Get an array with just the context lines (no indexes)
          match_with_context = line_block.map(&:first)
          # Remove 'nil' lines in case we are close to the first or last line
          match_with_context.compact!

          # Get the line number (1-indexed) of the first context line
          first_context_line_number = line_block[0][1] + 1

          greps << Gitlab::Git::BlobSnippet.new(
            ref,
            match_with_context,
            first_context_line_number,
            filename
          )
        end

        greps
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
    end
  end
end
