# Gitlab::Git::Repository is a wrapper around native Rugged::Repository object
require 'tempfile'
require 'forwardable'
require "rubygems/package"

module Gitlab
  module Git
    class Repository
      include Gitlab::Git::RepositoryMirroring
      include Gitlab::Git::Popen
      include Gitlab::EncodingHelper
      include Gitlab::Utils::StrongMemoize

      ALLOWED_OBJECT_DIRECTORIES_VARIABLES = %w[
        GIT_OBJECT_DIRECTORY
        GIT_ALTERNATE_OBJECT_DIRECTORIES
      ].freeze
      ALLOWED_OBJECT_RELATIVE_DIRECTORIES_VARIABLES = %w[
        GIT_OBJECT_DIRECTORY_RELATIVE
        GIT_ALTERNATE_OBJECT_DIRECTORIES_RELATIVE
      ].freeze
      SEARCH_CONTEXT_LINES = 3
      REBASE_WORKTREE_PREFIX = 'rebase'.freeze
      SQUASH_WORKTREE_PREFIX = 'squash'.freeze
      GITALY_INTERNAL_URL = 'ssh://gitaly/internal.git'.freeze
      GITLAB_PROJECTS_TIMEOUT = Gitlab.config.gitlab_shell.git_timeout
      EMPTY_REPOSITORY_CHECKSUM = '0000000000000000000000000000000000000000'.freeze

      NoRepository = Class.new(StandardError)
      InvalidBlobName = Class.new(StandardError)
      InvalidRef = Class.new(StandardError)
      GitError = Class.new(StandardError)
      DeleteBranchError = Class.new(StandardError)
      CreateTreeError = Class.new(StandardError)
      TagExistsError = Class.new(StandardError)
      ChecksumError = Class.new(StandardError)

      class << self
        # Unlike `new`, `create` takes the repository path
        def create(repo_path, bare: true, symlink_hooks_to: nil)
          FileUtils.mkdir_p(repo_path, mode: 0770)

          # Equivalent to `git --git-path=#{repo_path} init [--bare]`
          repo = Rugged::Repository.init_at(repo_path, bare)
          repo.close

          create_hooks(repo_path, symlink_hooks_to) if symlink_hooks_to.present?

          true
        end

        def create_hooks(repo_path, global_hooks_path)
          local_hooks_path = File.join(repo_path, 'hooks')
          real_local_hooks_path = :not_found

          begin
            real_local_hooks_path = File.realpath(local_hooks_path)
          rescue Errno::ENOENT
            # real_local_hooks_path == :not_found
          end

          # Do nothing if hooks already exist
          unless real_local_hooks_path == File.realpath(global_hooks_path)
            if File.exist?(local_hooks_path)
              # Move the existing hooks somewhere safe
              FileUtils.mv(
                local_hooks_path,
                "#{local_hooks_path}.old.#{Time.now.to_i}")
            end

            # Create the hooks symlink
            FileUtils.ln_sf(global_hooks_path, local_hooks_path)
          end

          true
        end
      end

      # Directory name of repo
      attr_reader :name

      # Relative path of repo
      attr_reader :relative_path

      # Rugged repo object
      attr_reader :rugged

      attr_reader :gitlab_projects, :storage, :gl_repository, :relative_path

      # This initializer method is only used on the client side (gitlab-ce).
      # Gitaly-ruby uses a different initializer.
      def initialize(storage, relative_path, gl_repository)
        @storage = storage
        @relative_path = relative_path
        @gl_repository = gl_repository

        @gitlab_projects = Gitlab::Git::GitlabProjects.new(
          storage,
          relative_path,
          global_hooks_path: Gitlab.config.gitlab_shell.hooks_path,
          logger: Rails.logger
        )

        @name = @relative_path.split("/").last
      end

      def ==(other)
        path == other.path
      end

      def path
        @path ||= File.join(
          Gitlab.config.repositories.storages[@storage].legacy_disk_path, @relative_path
        )
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

      def cleanup
        @rugged&.close
      end

      def circuit_breaker
        @circuit_breaker ||= Gitlab::Git::Storage::CircuitBreaker.for_storage(storage)
      end

      def exists?
        Gitlab::GitalyClient.migrate(:repository_exists, status: Gitlab::GitalyClient::MigrationStatus::OPT_OUT) do |enabled|
          if enabled
            gitaly_repository_client.exists?
          else
            circuit_breaker.perform do
              File.exist?(File.join(path, 'refs'))
            end
          end
        end
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

      def expire_has_local_branches_cache
        clear_memoization(:has_local_branches)
      end

      def has_local_branches?
        strong_memoize(:has_local_branches) do
          uncached_has_local_branches?
        end
      end

      # Git repository can contains some hidden refs like:
      #   /refs/notes/*
      #   /refs/git-as-svn/*
      #   /refs/pulls/*
      # This refs by default not visible in project page and not cloned to client side.
      alias_method :has_visible_content?, :has_local_branches?

      def has_local_branches_rugged?
        rugged.branches.each(:local).any? do |ref|
          begin
            ref.name && ref.target # ensures the branch is valid

            true
          rescue Rugged::ReferenceError
            false
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
        gitaly_migrate(:ref_exists,
                      status: Gitlab::GitalyClient::MigrationStatus::OPT_OUT) do |is_enabled|
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

      def batch_existence(object_ids, existing: true)
        filter_method = existing ? :select : :reject

        object_ids.public_send(filter_method) do |oid| # rubocop:disable GitlabSecurity/PublicSend
          rugged.exists?(oid)
        end
      end

      # Returns an Array of branch and tag names
      def ref_names
        branch_names + tag_names
      end

      def delete_all_refs_except(prefixes)
        gitaly_migrate(:ref_delete_refs) do |is_enabled|
          if is_enabled
            gitaly_ref_client.delete_refs(except_with_prefixes: prefixes)
          else
            delete_refs(*all_ref_names_except(prefixes))
          end
        end
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

      def archive_prefix(ref, sha, append_sha:)
        append_sha = (ref != sha) if append_sha.nil?

        project_name = self.name.chomp('.git')
        formatted_ref = ref.tr('/', '-')

        prefix_segments = [project_name, formatted_ref]
        prefix_segments << sha if append_sha

        prefix_segments.join('-')
      end

      def archive_metadata(ref, storage_path, format = "tar.gz", append_sha:)
        ref ||= root_ref
        commit = Gitlab::Git::Commit.find(self, ref)
        return {} if commit.nil?

        prefix = archive_prefix(ref, commit.id, append_sha: append_sha)

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
          after: nil,
          before: nil,
          all: false
        }

        options = default_options.merge(options)
        options[:offset] ||= 0

        limit = options[:limit]
        if limit == 0 || !limit.is_a?(Integer)
          raise ArgumentError.new("invalid Repository#log limit: #{limit.inspect}")
        end

        gitaly_migrate(:find_commits) do |is_enabled|
          if is_enabled
            gitaly_commit_client.find_commits(options)
          else
            raw_log(options).map { |c| Commit.decorate(self, c) }
          end
        end
      end

      # Used in gitaly-ruby
      def raw_log(options)
        sha =
          unless options[:all]
            actual_ref = options[:ref] || root_ref
            begin
              sha_from_ref(actual_ref)
            rescue Rugged::OdbError, Rugged::InvalidError, Rugged::ReferenceError
              # Return an empty array if the ref wasn't found
              return []
            end
          end

        log_by_shell(sha, options)
      end

      def count_commits(options)
        count_commits_options = process_count_commits_options(options)

        gitaly_migrate(:count_commits) do |is_enabled|
          if is_enabled
            count_commits_by_gitaly(count_commits_options)
          else
            count_commits_by_shelling_out(count_commits_options)
          end
        end
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
      def count_commits_between(from, to, options = {})
        count_commits(from: from, to: to, **options)
      end

      # old_rev and new_rev are commit ID's
      # the result of this method is an array of Gitlab::Git::RawDiffChange
      def raw_changes_between(old_rev, new_rev)
        return [] if new_rev.nil? || new_rev == Gitlab::Git::BLANK_SHA

        strong_memoize("changes_#{old_rev}_#{new_rev}".to_sym) do
          result = []

          circuit_breaker.perform do
            Open3.pipeline_r(git_diff_cmd(old_rev, new_rev), format_git_cat_file_script, git_cat_file_cmd) do |last_stdout, wait_threads|
              last_stdout.each_line { |line| result << ::Gitlab::Git::RawDiffChange.new(line.chomp!) }

              if wait_threads.any? { |waiter| !waiter.value&.success? }
                raise ::Gitlab::Git::Repository::GitError, "Unable to obtain changes between #{old_rev} and #{new_rev}"
              end
            end
          end

          result
        end
      end

      # Returns the SHA of the most recent common ancestor of +from+ and +to+
      def merge_base(from, to)
        gitaly_migrate(:merge_base) do |is_enabled|
          if is_enabled
            gitaly_repository_client.find_merge_base(from, to)
          else
            rugged_merge_base(from, to)
          end
        end
      end

      # Gitaly note: JV: check gitlab-ee before removing this method.
      def rugged_is_ancestor?(ancestor_id, descendant_id)
        return false if ancestor_id.nil? || descendant_id.nil?

        rugged_merge_base(ancestor_id, descendant_id) == ancestor_id
      rescue Rugged::OdbError
        false
      end

      # Returns true is +from+ is direct ancestor to +to+, otherwise false
      def ancestor?(from, to)
        Gitlab::GitalyClient.migrate(:is_ancestor) do |is_enabled|
          if is_enabled
            gitaly_commit_client.ancestor?(from, to)
          else
            rugged_is_ancestor?(from, to)
          end
        end
      end

      def merged_branch_names(branch_names = [])
        return [] unless root_ref

        root_sha = find_branch(root_ref)&.target

        return [] unless root_sha

        branches = gitaly_migrate(:merged_branch_names) do |is_enabled|
          if is_enabled
            gitaly_merged_branch_names(branch_names, root_sha)
          else
            git_merged_branch_names(branch_names, root_sha)
          end
        end

        Set.new(branches)
      end

      # Return an array of Diff objects that represent the diff
      # between +from+ and +to+.  See Diff::filter_diff_options for the allowed
      # diff options.  The +options+ hash can also include :break_rewrites to
      # split larger rewrites into delete/add pairs.
      def diff(from, to, options = {}, *paths)
        iterator = gitaly_migrate(:diff_between) do |is_enabled|
          if is_enabled
            gitaly_commit_client.diff(from, to, options.merge(paths: paths))
          else
            diff_patches(from, to, options, *paths)
          end
        end

        Gitlab::Git::DiffCollection.new(iterator, options)
      end

      # Returns a RefName for a given SHA
      def ref_name_for_sha(ref_path, sha)
        raise ArgumentError, "sha can't be empty" unless sha.present?

        gitaly_migrate(:find_ref_name) do |is_enabled|
          if is_enabled
            gitaly_ref_client.find_ref_name(sha, ref_path)
          else
            args = %W(for-each-ref --count=1 #{ref_path} --contains #{sha})

            # Not found -> ["", 0]
            # Found -> ["b8d95eb4969eefacb0a58f6a28f6803f8070e7b9 commit\trefs/environments/production/77\n", 0]
            run_git(args).first.split.last
          end
        end
      end

      # Get refs hash which key is is the commit id
      # and value is a Gitlab::Git::Tag or Gitlab::Git::Branch
      # Note that both inherit from Gitlab::Git::Ref
      def refs_hash
        return @refs_hash if @refs_hash

        @refs_hash = Hash.new { |h, k| h[k] = [] }

        (tags + branches).each do |ref|
          next unless ref.target && ref.name

          @refs_hash[ref.dereferenced_target.id] << ref.name
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
            rugged_commit_count(ref)
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
        gitaly_migrate(:operation_user_create_branch, status: Gitlab::GitalyClient::MigrationStatus::OPT_OUT) do |is_enabled|
          if is_enabled
            gitaly_add_branch(branch_name, user, target)
          else
            rugged_add_branch(branch_name, user, target)
          end
        end
      end

      def add_tag(tag_name, user:, target:, message: nil)
        gitaly_migrate(:operation_user_add_tag, status: Gitlab::GitalyClient::MigrationStatus::OPT_OUT) do |is_enabled|
          if is_enabled
            gitaly_add_tag(tag_name, user: user, target: target, message: message)
          else
            rugged_add_tag(tag_name, user: user, target: target, message: message)
          end
        end
      end

      def rm_branch(branch_name, user:)
        gitaly_migrate(:operation_user_delete_branch, status: Gitlab::GitalyClient::MigrationStatus::OPT_OUT) do |is_enabled|
          if is_enabled
            gitaly_operations_client.user_delete_branch(branch_name, user)
          else
            OperationService.new(user, self).rm_branch(find_branch(branch_name))
          end
        end
      end

      def rm_tag(tag_name, user:)
        gitaly_migrate(:operation_user_delete_tag) do |is_enabled|
          if is_enabled
            gitaly_operations_client.rm_tag(tag_name, user)
          else
            Gitlab::Git::OperationService.new(user, self).rm_tag(find_tag(tag_name))
          end
        end
      end

      def find_tag(name)
        tags.find { |tag| tag.name == name }
      end

      def merge(user, source_sha, target_branch, message, &block)
        gitaly_migrate(:operation_user_merge_branch) do |is_enabled|
          if is_enabled
            gitaly_operation_client.user_merge_branch(user, source_sha, target_branch, message, &block)
          else
            rugged_merge(user, source_sha, target_branch, message, &block)
          end
        end
      end

      def rugged_merge(user, source_sha, target_branch, message)
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

      def ff_merge(user, source_sha, target_branch)
        gitaly_migrate(:operation_user_ff_branch) do |is_enabled|
          if is_enabled
            gitaly_ff_merge(user, source_sha, target_branch)
          else
            rugged_ff_merge(user, source_sha, target_branch)
          end
        end
      end

      def revert(user:, commit:, branch_name:, message:, start_branch_name:, start_repository:)
        gitaly_migrate(:revert, status: Gitlab::GitalyClient::MigrationStatus::OPT_OUT) do |is_enabled|
          args = {
            user: user,
            commit: commit,
            branch_name: branch_name,
            message: message,
            start_branch_name: start_branch_name,
            start_repository: start_repository
          }

          if is_enabled
            gitaly_operations_client.user_revert(args)
          else
            rugged_revert(args)
          end
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
        gitaly_migrate(:cherry_pick) do |is_enabled|
          args = {
            user: user,
            commit: commit,
            branch_name: branch_name,
            message: message,
            start_branch_name: start_branch_name,
            start_repository: start_repository
          }

          if is_enabled
            gitaly_operations_client.user_cherry_pick(args)
          else
            rugged_cherry_pick(args)
          end
        end
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
        gitaly_migrate(:delete_branch, status: Gitlab::GitalyClient::MigrationStatus::OPT_OUT) do |is_enabled|
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
        gitaly_migrate(:delete_refs,
                      status: Gitlab::GitalyClient::MigrationStatus::OPT_OUT) do |is_enabled|
          if is_enabled
            gitaly_delete_refs(*ref_names)
          else
            git_delete_refs(*ref_names)
          end
        end
      end

      # Create a new branch named **ref+ based on **stat_point+, HEAD by default
      #
      # Examples:
      #   create_branch("feature")
      #   create_branch("other-feature", "master")
      def create_branch(ref, start_point = "HEAD")
        gitaly_migrate(:create_branch, status: Gitlab::GitalyClient::MigrationStatus::OPT_OUT) do |is_enabled|
          if is_enabled
            gitaly_ref_client.create_branch(ref, start_point)
          else
            rugged_create_branch(ref, start_point)
          end
        end
      end

      # If `mirror_refmap` is present the remote is set as mirror with that mapping
      def add_remote(remote_name, url, mirror_refmap: nil)
        gitaly_migrate(:remote_add_remote) do |is_enabled|
          if is_enabled
            gitaly_remote_client.add_remote(remote_name, url, mirror_refmap)
          else
            rugged_add_remote(remote_name, url, mirror_refmap)
          end
        end
      end

      def remove_remote(remote_name)
        gitaly_migrate(:remote_remove_remote) do |is_enabled|
          if is_enabled
            gitaly_remote_client.remove_remote(remote_name)
          else
            rugged_remove_remote(remote_name)
          end
        end
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

      def info_attributes
        return @info_attributes if @info_attributes

        content =
          gitaly_migrate(:get_info_attributes) do |is_enabled|
            if is_enabled
              gitaly_repository_client.info_attributes
            else
              attributes_path = File.join(File.expand_path(path), 'info', 'attributes')

              if File.exist?(attributes_path)
                File.read(attributes_path)
              else
                ""
              end
            end
          end

        @info_attributes = AttributesParser.new(content)
      end

      # Returns the Git attributes for the given file path.
      #
      # See `Gitlab::Git::Attributes` for more information.
      def attributes(path)
        info_attributes.attributes(path)
      end

      def gitattribute(path, name)
        attributes(path)[name]
      end

      # Check .gitattributes for a given ref
      #
      # This only checks the root .gitattributes file,
      # it does not traverse subfolders to find additional .gitattributes files
      #
      # This method is around 30 times slower than `attributes`, which uses
      # `$GIT_DIR/info/attributes`. Consider caching AttributesAtRefParser
      # and reusing that for multiple calls instead of this method.
      def attributes_at(ref, file_path)
        parser = AttributesAtRefParser.new(self, ref)
        parser.attributes(file_path)
      end

      def languages(ref = nil)
        gitaly_migrate(:commit_languages, status: Gitlab::GitalyClient::MigrationStatus::OPT_OUT) do |is_enabled|
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

      def license_short_name
        gitaly_migrate(:license_short_name,
                       status: Gitlab::GitalyClient::MigrationStatus::OPT_OUT) do |is_enabled|
          if is_enabled
            gitaly_repository_client.license_short_name
          else
            begin
              # The licensee gem creates a Rugged object from the path:
              # https://github.com/benbalter/licensee/blob/v8.7.0/lib/licensee/projects/git_project.rb
              Licensee.license(path).try(:key)
            rescue Rugged::Error
            end
          end
        end
      end

      def with_repo_branch_commit(start_repository, start_branch_name)
        Gitlab::Git.check_namespace!(start_repository)
        start_repository = RemoteRepository.new(start_repository) unless start_repository.is_a?(RemoteRepository)

        return yield nil if start_repository.empty?

        if start_repository.same_repository?(self)
          yield commit(start_branch_name)
        else
          start_commit_id = start_repository.commit_id(start_branch_name)

          return yield nil unless start_commit_id

          if branch_commit = commit(start_commit_id)
            yield branch_commit
          else
            with_repo_tmp_commit(
              start_repository, start_branch_name, start_commit_id) do |tmp_commit|
              yield tmp_commit
            end
          end
        end
      end

      def with_repo_tmp_commit(start_repository, start_branch_name, sha)
        source_ref = start_branch_name

        unless Gitlab::Git.branch_ref?(source_ref)
          source_ref = "#{Gitlab::Git::BRANCH_REF_PREFIX}#{source_ref}"
        end

        tmp_ref = fetch_ref(
          start_repository,
          source_ref: source_ref,
          target_ref: "refs/tmp/#{SecureRandom.hex}"
        )

        yield commit(sha)
      ensure
        delete_refs(tmp_ref) if tmp_ref
      end

      def fetch_source_branch!(source_repository, source_branch, local_ref)
        Gitlab::GitalyClient.migrate(:fetch_source_branch) do |is_enabled|
          if is_enabled
            gitaly_repository_client.fetch_source_branch(source_repository, source_branch, local_ref)
          else
            rugged_fetch_source_branch(source_repository, source_branch, local_ref)
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

      def write_ref(ref_path, ref, old_ref: nil, shell: true)
        ref_path = "#{Gitlab::Git::BRANCH_REF_PREFIX}#{ref_path}" unless ref_path.start_with?("refs/") || ref_path == "HEAD"

        gitaly_migrate(:write_ref) do |is_enabled|
          if is_enabled
            gitaly_repository_client.write_ref(ref_path, ref, old_ref, shell)
          else
            local_write_ref(ref_path, ref, old_ref: old_ref, shell: shell)
          end
        end
      end

      def fetch_ref(source_repository, source_ref:, target_ref:)
        Gitlab::Git.check_namespace!(source_repository)
        source_repository = RemoteRepository.new(source_repository) unless source_repository.is_a?(RemoteRepository)

        message, status = GitalyClient.migrate(:fetch_ref) do |is_enabled|
          if is_enabled
            gitaly_fetch_ref(source_repository, source_ref: source_ref, target_ref: target_ref)
          else
            local_fetch_ref(source_repository.path, source_ref: source_ref, target_ref: target_ref)
          end
        end

        # Make sure ref was created, and raise Rugged::ReferenceError when not
        raise Rugged::ReferenceError, message if status != 0

        target_ref
      end

      # Refactoring aid; allows us to copy code from app/models/repository.rb
      def commit(ref = 'HEAD')
        Gitlab::Git::Commit.find(self, ref)
      end

      def empty?
        !has_visible_content?
      end

      def fetch_repository_as_mirror(repository)
        gitaly_migrate(:remote_fetch_internal_remote) do |is_enabled|
          if is_enabled
            gitaly_remote_client.fetch_internal_remote(repository)
          else
            rugged_fetch_repository_as_mirror(repository)
          end
        end
      end

      def blob_at(sha, path)
        Gitlab::Git::Blob.find(self, sha, path) unless Gitlab::Git.blank_ref?(sha)
      end

      # Items should be of format [[commit_id, path], [commit_id1, path1]]
      def batch_blobs(items, blob_size_limit: Gitlab::Git::Blob::MAX_DATA_DISPLAY_SIZE)
        Gitlab::Git::Blob.batch(self, items, blob_size_limit: blob_size_limit)
      end

      def commit_index(user, branch_name, index, options)
        committer = user_to_committer(user)

        OperationService.new(user, self).with_branch(branch_name) do
          commit_params = options.merge(
            tree: index.write_tree(rugged),
            author: committer,
            committer: committer
          )

          create_commit(commit_params)
        end
      end

      def fsck
        msg, status = gitaly_repository_client.fsck

        raise GitError.new("Could not fsck repository: #{msg}") unless status.zero?
      end

      def create_from_bundle(bundle_path)
        gitaly_migrate(:create_repo_from_bundle) do |is_enabled|
          if is_enabled
            gitaly_repository_client.create_from_bundle(bundle_path)
          else
            run_git!(%W(clone --bare -- #{bundle_path} #{path}), chdir: nil)
            self.class.create_hooks(path, File.expand_path(Gitlab.config.gitlab_shell.hooks_path))
          end
        end

        true
      end

      def create_from_snapshot(url, auth)
        gitaly_repository_client.create_from_snapshot(url, auth)
      end

      def rebase(user, rebase_id, branch:, branch_sha:, remote_repository:, remote_branch:)
        gitaly_migrate(:rebase) do |is_enabled|
          if is_enabled
            gitaly_rebase(user, rebase_id,
                          branch: branch,
                          branch_sha: branch_sha,
                          remote_repository: remote_repository,
                          remote_branch: remote_branch)
          else
            git_rebase(user, rebase_id,
                       branch: branch,
                       branch_sha: branch_sha,
                       remote_repository: remote_repository,
                       remote_branch: remote_branch)
          end
        end
      end

      def rebase_in_progress?(rebase_id)
        gitaly_migrate(:rebase_in_progress) do |is_enabled|
          if is_enabled
            gitaly_repository_client.rebase_in_progress?(rebase_id)
          else
            fresh_worktree?(worktree_path(REBASE_WORKTREE_PREFIX, rebase_id))
          end
        end
      end

      def squash(user, squash_id, branch:, start_sha:, end_sha:, author:, message:)
        gitaly_migrate(:squash) do |is_enabled|
          if is_enabled
            gitaly_operation_client.user_squash(user, squash_id, branch,
              start_sha, end_sha, author, message)
          else
            git_squash(user, squash_id, branch, start_sha, end_sha, author, message)
          end
        end
      end

      def squash_in_progress?(squash_id)
        gitaly_migrate(:squash_in_progress) do |is_enabled|
          if is_enabled
            gitaly_repository_client.squash_in_progress?(squash_id)
          else
            fresh_worktree?(worktree_path(SQUASH_WORKTREE_PREFIX, squash_id))
          end
        end
      end

      def push_remote_branches(remote_name, branch_names, forced: true)
        success = @gitlab_projects.push_branches(remote_name, GITLAB_PROJECTS_TIMEOUT, forced, branch_names)

        success || gitlab_projects_error
      end

      def delete_remote_branches(remote_name, branch_names)
        success = @gitlab_projects.delete_remote_branches(remote_name, branch_names)

        success || gitlab_projects_error
      end

      def delete_remote_branches(remote_name, branch_names)
        success = @gitlab_projects.delete_remote_branches(remote_name, branch_names)

        success || gitlab_projects_error
      end

      def bundle_to_disk(save_path)
        gitaly_migrate(:bundle_to_disk) do |is_enabled|
          if is_enabled
            gitaly_repository_client.create_bundle(save_path)
          else
            run_git!(%W(bundle create #{save_path} --all))
          end
        end

        true
      end

      # rubocop:disable Metrics/ParameterLists
      def multi_action(
        user, branch_name:, message:, actions:,
        author_email: nil, author_name: nil,
        start_branch_name: nil, start_repository: self)

        gitaly_migrate(:operation_user_commit_files) do |is_enabled|
          if is_enabled
            gitaly_operation_client.user_commit_files(user, branch_name,
              message, actions, author_email, author_name,
              start_branch_name, start_repository)
          else
            rugged_multi_action(user, branch_name, message, actions,
              author_email, author_name, start_branch_name, start_repository)
          end
        end
      end
      # rubocop:enable Metrics/ParameterLists

      def write_config(full_path:)
        return unless full_path.present?

        gitaly_migrate(:write_config) do |is_enabled|
          if is_enabled
            gitaly_repository_client.write_config(full_path: full_path)
          else
            rugged_write_config(full_path: full_path)
          end
        end
      end

      def gitaly_repository
        Gitlab::GitalyClient::Util.repository(@storage, @relative_path, @gl_repository)
      end

      def gitaly_operations_client
        @gitaly_operations_client ||= Gitlab::GitalyClient::OperationService.new(self)
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

      def gitaly_operation_client
        @gitaly_operation_client ||= Gitlab::GitalyClient::OperationService.new(self)
      end

      def gitaly_remote_client
        @gitaly_remote_client ||= Gitlab::GitalyClient::RemoteService.new(self)
      end

      def gitaly_blob_client
        @gitaly_blob_client ||= Gitlab::GitalyClient::BlobService.new(self)
      end

      def gitaly_conflicts_client(our_commit_oid, their_commit_oid)
        Gitlab::GitalyClient::ConflictsService.new(self, our_commit_oid, their_commit_oid)
      end

      def gitaly_migrate(method, status: Gitlab::GitalyClient::MigrationStatus::OPT_IN, &block)
        Gitlab::GitalyClient.migrate(method, status: status, &block)
      rescue GRPC::NotFound => e
        raise NoRepository.new(e)
      rescue GRPC::InvalidArgument => e
        raise ArgumentError.new(e)
      rescue GRPC::BadStatus => e
        raise CommandError.new(e)
      end

      def clean_stale_repository_files
        gitaly_migrate(:repository_cleanup, status: Gitlab::GitalyClient::MigrationStatus::OPT_OUT) do |is_enabled|
          gitaly_repository_client.cleanup if is_enabled && exists?
        end
      rescue Gitlab::Git::CommandError => e # Don't fail if we can't cleanup
        Rails.logger.error("Unable to clean repository on storage #{storage} with path #{path}: #{e.message}")
        Gitlab::Metrics.counter(
          :failed_repository_cleanup_total,
          'Number of failed repository cleanup events'
        ).increment
      end

      def branch_names_contains_sha(sha)
        gitaly_migrate(:branch_names_contains_sha,
                      status: Gitlab::GitalyClient::MigrationStatus::OPT_OUT) do |is_enabled|
          if is_enabled
            gitaly_ref_client.branch_names_contains_sha(sha)
          else
            refs_contains_sha('refs/heads/', sha)
          end
        end
      end

      def tag_names_contains_sha(sha)
        gitaly_migrate(:tag_names_contains_sha,
                       status: Gitlab::GitalyClient::MigrationStatus::OPT_OUT) do |is_enabled|
          if is_enabled
            gitaly_ref_client.tag_names_contains_sha(sha)
          else
            refs_contains_sha('refs/tags/', sha)
          end
        end
      end

      def search_files_by_content(query, ref)
        return [] if empty? || query.blank?

        offset = 2
        args = %W(grep -i -I -n -z --before-context #{offset} --after-context #{offset} -E -e #{Regexp.escape(query)} #{ref || root_ref})

        run_git(args).first.scrub.split(/^--\n/)
      end

      def can_be_merged?(source_sha, target_branch)
        gitaly_migrate(:can_be_merged) do |is_enabled|
          if is_enabled
            gitaly_can_be_merged?(source_sha, find_branch(target_branch, true).target)
          else
            rugged_can_be_merged?(source_sha, target_branch)
          end
        end
      end

      def search_files_by_name(query, ref)
        safe_query = Regexp.escape(query.sub(%r{^/*}, ""))

        return [] if empty? || safe_query.blank?

        args = %W(ls-tree -r --name-status --full-tree #{ref || root_ref} -- #{safe_query})

        run_git(args).first.lines.map(&:strip)
      end

      def find_commits_by_message(query, ref, path, limit, offset)
        gitaly_migrate(:commits_by_message) do |is_enabled|
          if is_enabled
            find_commits_by_message_by_gitaly(query, ref, path, limit, offset)
          else
            find_commits_by_message_by_shelling_out(query, ref, path, limit, offset)
          end
        end
      end

      def shell_blame(sha, path)
        output, _status = run_git(%W(blame -p #{sha} -- #{path}))
        output
      end

      def last_commit_for_path(sha, path)
        gitaly_migrate(:last_commit_for_path) do |is_enabled|
          if is_enabled
            last_commit_for_path_by_gitaly(sha, path)
          else
            last_commit_for_path_by_rugged(sha, path)
          end
        end
      end

      def rev_list(including: [], excluding: [], objects: false, &block)
        args = ['rev-list']

        args.push(*rev_list_param(including))

        exclude_param = *rev_list_param(excluding)
        if exclude_param.any?
          args.push('--not')
          args.push(*exclude_param)
        end

        args.push('--objects') if objects

        run_git!(args, lazy_block: block)
      end

      def missed_ref(oldrev, newrev)
        run_git!(['rev-list', '--max-count=1', oldrev, "^#{newrev}"])
      end

      def with_worktree(worktree_path, branch, sparse_checkout_files: nil, env:)
        base_args = %w(worktree add --detach)

        # Note that we _don't_ want to test for `.present?` here: If the caller
        # passes an non nil empty value it means it still wants sparse checkout
        # but just isn't interested in any file, perhaps because it wants to
        # checkout files in by a changeset but that changeset only adds files.
        if sparse_checkout_files
          # Create worktree without checking out
          run_git!(base_args + ['--no-checkout', worktree_path], env: env)
          worktree_git_path = run_git!(%w(rev-parse --git-dir), chdir: worktree_path).chomp

          configure_sparse_checkout(worktree_git_path, sparse_checkout_files)

          # After sparse checkout configuration, checkout `branch` in worktree
          run_git!(%W(checkout --detach #{branch}), chdir: worktree_path, env: env)
        else
          # Create worktree and checkout `branch` in it
          run_git!(base_args + [worktree_path, branch], env: env)
        end

        yield
      ensure
        FileUtils.rm_rf(worktree_path) if File.exist?(worktree_path)
        FileUtils.rm_rf(worktree_git_path) if worktree_git_path && File.exist?(worktree_git_path)
      end

      def checksum
        gitaly_migrate(:calculate_checksum) do |is_enabled|
          if is_enabled
            gitaly_repository_client.calculate_checksum
          else
            calculate_checksum_by_shelling_out
          end
        end
      end

      private

      def uncached_has_local_branches?
        gitaly_migrate(:has_local_branches, status: Gitlab::GitalyClient::MigrationStatus::OPT_OUT) do |is_enabled|
          if is_enabled
            gitaly_repository_client.has_local_branches?
          else
            has_local_branches_rugged?
          end
        end
      end

      def local_write_ref(ref_path, ref, old_ref: nil, shell: true)
        if shell
          shell_write_ref(ref_path, ref, old_ref)
        else
          rugged_write_ref(ref_path, ref)
        end
      end

      def refs_contains_sha(refs_prefix, sha)
        refs_prefix << "/" unless refs_prefix.ends_with?('/')

        # By forcing the output to %(refname) each line wiht a ref will start with
        # the ref prefix. All other lines can be discarded.
        args = %W(for-each-ref --contains=#{sha} --format=%(refname) #{refs_prefix})
        names, code = run_git(args)

        return [] unless code.zero?

        refs = []
        left_slice_count = refs_prefix.length
        names.lines.each do |line|
          next unless line.start_with?(refs_prefix)

          refs << encode_utf8(line.rstrip[left_slice_count..-1])
        end

        refs
      end

      def rugged_write_config(full_path:)
        rugged.config['gitlab.fullpath'] = full_path
      end

      def shell_write_ref(ref_path, ref, old_ref)
        raise ArgumentError, "invalid ref_path #{ref_path.inspect}" if ref_path.include?(' ')
        raise ArgumentError, "invalid ref #{ref.inspect}" if ref.include?("\x00")
        raise ArgumentError, "invalid old_ref #{old_ref.inspect}" if !old_ref.nil? && old_ref.include?("\x00")

        input = "update #{ref_path}\x00#{ref}\x00#{old_ref}\x00"
        run_git!(%w[update-ref --stdin -z]) { |stdin| stdin.write(input) }
      end

      def rugged_write_ref(ref_path, ref)
        rugged.references.create(ref_path, ref, force: true)
      rescue Rugged::ReferenceError => ex
        Rails.logger.error "Unable to create #{ref_path} reference for repository #{path}: #{ex}"
      rescue Rugged::OSError => ex
        raise unless ex.message =~ /Failed to create locked file/ && ex.message =~ /File exists/

        Rails.logger.error "Unable to create #{ref_path} reference for repository #{path}: #{ex}"
      end

      def run_git(args, chdir: path, env: {}, nice: false, lazy_block: nil, &block)
        cmd = [Gitlab.config.git.bin_path, *args]
        cmd.unshift("nice") if nice

        object_directories = alternate_object_directories
        if object_directories.any?
          env['GIT_ALTERNATE_OBJECT_DIRECTORIES'] = object_directories.join(File::PATH_SEPARATOR)
        end

        circuit_breaker.perform do
          popen(cmd, chdir, env, lazy_block: lazy_block, &block)
        end
      end

      def run_git!(args, chdir: path, env: {}, nice: false, lazy_block: nil, &block)
        output, status = run_git(args, chdir: chdir, env: env, nice: nice, lazy_block: lazy_block, &block)

        raise GitError, output unless status.zero?

        output
      end

      def run_git_with_timeout(args, timeout, env: {})
        circuit_breaker.perform do
          popen_with_timeout([Gitlab.config.git.bin_path, *args], timeout, path, env)
        end
      end

      def fresh_worktree?(path)
        File.exist?(path) && !clean_stuck_worktree(path)
      end

      def clean_stuck_worktree(path)
        return false unless File.mtime(path) < 15.minutes.ago

        FileUtils.rm_rf(path)
        true
      end

      # Adding a worktree means checking out the repository. For large repos,
      # this can be very expensive, so set up sparse checkout for the worktree
      # to only check out the files we're interested in.
      def configure_sparse_checkout(worktree_git_path, files)
        run_git!(%w(config core.sparseCheckout true))

        return if files.empty?

        worktree_info_path = File.join(worktree_git_path, 'info')
        FileUtils.mkdir_p(worktree_info_path)
        File.write(File.join(worktree_info_path, 'sparse-checkout'), files)
      end

      def rugged_fetch_source_branch(source_repository, source_branch, local_ref)
        with_repo_branch_commit(source_repository, source_branch) do |commit|
          if commit
            write_ref(local_ref, commit.sha)
            true
          else
            false
          end
        end
      end

      def worktree_path(prefix, id)
        id = id.to_s
        raise ArgumentError, "worktree id can't be empty" unless id.present?
        raise ArgumentError, "worktree id can't contain slashes " if id.include?("/")

        File.join(path, 'gitlab-worktree', "#{prefix}-#{id}")
      end

      def git_env_for_user(user)
        {
          'GIT_COMMITTER_NAME' => user.name,
          'GIT_COMMITTER_EMAIL' => user.email,
          'GL_ID' => Gitlab::GlId.gl_id(user),
          'GL_PROTOCOL' => Gitlab::Git::Hook::GL_PROTOCOL,
          'GL_REPOSITORY' => gl_repository
        }
      end

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

      def git_merged_branch_names(branch_names, root_sha)
        git_arguments =
          %W[branch --merged #{root_sha}
             --format=%(refname:short)\ %(objectname)] + branch_names

        lines = run_git(git_arguments).first.lines

        lines.each_with_object([]) do |line, branches|
          name, sha = line.strip.split(' ', 2)

          branches << name if sha != root_sha
        end
      end

      def gitaly_merged_branch_names(branch_names, root_sha)
        qualified_branch_names = branch_names.map { |b| "refs/heads/#{b}" }

        gitaly_ref_client.merged_branches(qualified_branch_names)
          .reject { |b| b.target == root_sha }
          .map(&:name)
      end

      def process_count_commits_options(options)
        if options[:from] || options[:to]
          ref =
            if options[:left_right] # Compare with merge-base for left-right
              "#{options[:from]}...#{options[:to]}"
            else
              "#{options[:from]}..#{options[:to]}"
            end

          options.merge(ref: ref)

        elsif options[:ref] && options[:left_right]
          from, to = options[:ref].match(/\A([^\.]*)\.{2,3}([^\.]*)\z/)[1..2]

          options.merge(from: from, to: to)
        else
          options
        end
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

        cmd = %w[log]
        cmd << "--max-count=#{limit}"
        cmd << '--format=%H'
        cmd << "--skip=#{offset}" unless offset_in_ruby
        cmd << '--follow' if use_follow_flag
        cmd << '--no-merges' if options[:skip_merges]
        cmd << "--after=#{options[:after].iso8601}" if options[:after]
        cmd << "--before=#{options[:before].iso8601}" if options[:before]

        if options[:all]
          cmd += %w[--all --reverse]
        else
          cmd << sha
        end

        # :path can be a string or an array of strings
        if options[:path].present?
          cmd << '--'
          cmd += Array(options[:path])
        end

        raw_output, _status = run_git(cmd)
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
        relative_object_directories.map { |d| File.join(path, d) }
      end

      def relative_object_directories
        Gitlab::Git::HookEnv.all(gl_repository).values_at(*ALLOWED_OBJECT_RELATIVE_DIRECTORIES_VARIABLES).flatten.compact
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
        sha = last_commit_id_for_path_by_shelling_out(sha, path)
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
        if options[:left_right]
          from = options[:from]
          to = options[:to]

          right_count = gitaly_commit_client
            .commit_count("#{from}..#{to}", options)
          left_count = gitaly_commit_client
            .commit_count("#{to}..#{from}", options)

          [left_count, right_count]
        else
          gitaly_commit_client.commit_count(options[:ref], options)
        end
      end

      def count_commits_by_shelling_out(options)
        cmd = count_commits_shelling_command(options)

        raw_output, _status = run_git(cmd)

        process_count_commits_raw_output(raw_output, options)
      end

      def count_commits_shelling_command(options)
        cmd = %w[rev-list]
        cmd << "--after=#{options[:after].iso8601}" if options[:after]
        cmd << "--before=#{options[:before].iso8601}" if options[:before]
        cmd << "--max-count=#{options[:max_count]}" if options[:max_count]
        cmd << "--left-right" if options[:left_right]
        cmd << '--count'

        cmd << if options[:all]
                 '--all'
               elsif options[:ref]
                 options[:ref]
               else
                 raise ArgumentError, "Please specify a valid ref or set the 'all' attribute to true"
               end

        cmd += %W[-- #{options[:path]}] if options[:path].present?
        cmd
      end

      def process_count_commits_raw_output(raw_output, options)
        if options[:left_right]
          result = raw_output.scan(/\d+/).map(&:to_i)

          if result.sum != options[:max_count]
            result
          else # Reaching max count, right is not accurate
            right_option =
              process_count_commits_options(options
                .except(:left_right, :from, :to)
                .merge(ref: options[:to]))

            right = count_commits_by_shelling_out(right_option)

            [result.first, right] # left should be accurate in the first call
          end
        else
          raw_output.to_i
        end
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

        cmd = %W(ls-tree -r --full-tree --full-name -- #{actual_ref})
        raw_output, _status = run_git(cmd)

        lines = raw_output.split("\n").map do |f|
          stuff, path = f.split("\t")
          _mode, type, _sha = stuff.split(" ")
          path if type == "blob"
          # Contain only blob type
        end

        lines.compact
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

      def gitaly_add_tag(tag_name, user:, target:, message: nil)
        gitaly_operations_client.add_tag(tag_name, user, target, message)
      end

      def rugged_add_tag(tag_name, user:, target:, message: nil)
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

        Gitlab::Git::OperationService.new(user, self).add_tag(tag_name, target_object.oid, options)

        find_tag(tag_name)
      rescue Rugged::ReferenceError => ex
        raise InvalidRef, ex
      rescue Rugged::TagError
        raise TagExistsError
      end

      def rugged_create_branch(ref, start_point)
        rugged_ref = rugged.branches.create(ref, start_point)
        target_commit = Gitlab::Git::Commit.find(self, rugged_ref.target)
        Gitlab::Git::Branch.new(self, rugged_ref.name, rugged_ref.target, target_commit)
      rescue Rugged::ReferenceError => e
        raise InvalidRef.new("Branch #{ref} already exists") if e.to_s =~ %r{'refs/heads/#{ref}'}

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

      def rugged_revert(user:, commit:, branch_name:, message:, start_branch_name:, start_repository:)
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

      def gitaly_add_branch(branch_name, user, target)
        gitaly_operation_client.user_create_branch(branch_name, user, target)
      rescue GRPC::FailedPrecondition => ex
        raise InvalidRef, ex
      end

      def rugged_add_branch(branch_name, user, target)
        target_object = Ref.dereference_object(lookup(target))
        raise InvalidRef.new("target not found: #{target}") unless target_object

        OperationService.new(user, self).add_branch(branch_name, target_object.oid)
        find_branch(branch_name)
      rescue Rugged::ReferenceError => ex
        raise InvalidRef, ex
      end

      def rugged_cherry_pick(user:, commit:, branch_name:, message:, start_branch_name:, start_repository:)
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

      def gitaly_rebase(user, rebase_id, branch:, branch_sha:, remote_repository:, remote_branch:)
        gitaly_operation_client.user_rebase(user, rebase_id,
                                            branch: branch,
                                            branch_sha: branch_sha,
                                            remote_repository: remote_repository,
                                            remote_branch: remote_branch)
      end

      def git_rebase(user, rebase_id, branch:, branch_sha:, remote_repository:, remote_branch:)
        rebase_path = worktree_path(REBASE_WORKTREE_PREFIX, rebase_id)
        env = git_env_for_user(user)

        if remote_repository.is_a?(RemoteRepository)
          env.merge!(remote_repository.fetch_env)
          remote_repo_path = GITALY_INTERNAL_URL
        else
          remote_repo_path = remote_repository.path
        end

        with_worktree(rebase_path, branch, env: env) do
          run_git!(
            %W(pull --rebase #{remote_repo_path} #{remote_branch}),
            chdir: rebase_path, env: env
          )

          rebase_sha = run_git!(%w(rev-parse HEAD), chdir: rebase_path, env: env).strip

          Gitlab::Git::OperationService.new(user, self)
            .update_branch(branch, rebase_sha, branch_sha)

          rebase_sha
        end
      end

      def git_squash(user, squash_id, branch, start_sha, end_sha, author, message)
        squash_path = worktree_path(SQUASH_WORKTREE_PREFIX, squash_id)
        env = git_env_for_user(user).merge(
          'GIT_AUTHOR_NAME' => author.name,
          'GIT_AUTHOR_EMAIL' => author.email
        )
        diff_range = "#{start_sha}...#{end_sha}"
        diff_files = run_git!(
          %W(diff --name-only --diff-filter=ar --binary #{diff_range})
        ).chomp

        with_worktree(squash_path, branch, sparse_checkout_files: diff_files, env: env) do
          # Apply diff of the `diff_range` to the worktree
          diff = run_git!(%W(diff --binary #{diff_range}))
          run_git!(%w(apply --index --whitespace=nowarn), chdir: squash_path, env: env) do |stdin|
            stdin.binmode
            stdin.write(diff)
          end

          # Commit the `diff_range` diff
          run_git!(%W(commit --no-verify --message #{message}), chdir: squash_path, env: env)

          # Return the squash sha. May print a warning for ambiguous refs, but
          # we can ignore that with `--quiet` and just take the SHA, if present.
          # HEAD here always refers to the current HEAD commit, even if there is
          # another ref called HEAD.
          run_git!(
            %w(rev-parse --quiet --verify HEAD), chdir: squash_path, env: env
          ).chomp
        end
      end

      def local_fetch_ref(source_path, source_ref:, target_ref:)
        args = %W(fetch --no-tags -f #{source_path} #{source_ref}:#{target_ref})
        run_git(args)
      end

      def gitaly_fetch_ref(source_repository, source_ref:, target_ref:)
        args = %W(fetch --no-tags -f #{GITALY_INTERNAL_URL} #{source_ref}:#{target_ref})

        run_git(args, env: source_repository.fetch_env)
      end

      def gitaly_ff_merge(user, source_sha, target_branch)
        gitaly_operations_client.user_ff_branch(user, source_sha, target_branch)
      rescue GRPC::FailedPrecondition => e
        raise CommitError, e
      end

      def rugged_ff_merge(user, source_sha, target_branch)
        OperationService.new(user, self).with_branch(target_branch) do |our_commit|
          raise ArgumentError, 'Invalid merge target' unless our_commit

          source_sha
        end
      rescue Rugged::ReferenceError, InvalidRef
        raise ArgumentError, 'Invalid merge source'
      end

      def rugged_add_remote(remote_name, url, mirror_refmap)
        rugged.remotes.create(remote_name, url)

        set_remote_as_mirror(remote_name, refmap: mirror_refmap) if mirror_refmap
      rescue Rugged::ConfigError
        remote_update(remote_name, url: url)
      end

      def git_delete_refs(*ref_names)
        instructions = ref_names.map do |ref|
          "delete #{ref}\x00\x00"
        end

        message, status = run_git(%w[update-ref --stdin -z]) do |stdin|
          stdin.write(instructions.join)
        end

        unless status.zero?
          raise GitError.new("Could not delete refs #{ref_names}: #{message}")
        end
      end

      def gitaly_delete_refs(*ref_names)
        gitaly_ref_client.delete_refs(refs: ref_names)
      end

      def rugged_remove_remote(remote_name)
        # When a remote is deleted all its remote refs are deleted too, but in
        # the case of mirrors we map its refs (that would usualy go under
        # [remote_name]/) to the top level namespace. We clean the mapping so
        # those don't get deleted.
        if rugged.config["remote.#{remote_name}.mirror"]
          rugged.config.delete("remote.#{remote_name}.fetch")
        end

        rugged.remotes.delete(remote_name)
        true
      rescue Rugged::ConfigError
        false
      end

      def rugged_fetch_repository_as_mirror(repository)
        remote_name = "tmp-#{SecureRandom.hex}"
        repository = RemoteRepository.new(repository) unless repository.is_a?(RemoteRepository)

        add_remote(remote_name, GITALY_INTERNAL_URL, mirror_refmap: :all_refs)
        fetch_remote(remote_name, env: repository.fetch_env)
      ensure
        remove_remote(remote_name)
      end

      def rugged_multi_action(
        user, branch_name, message, actions, author_email, author_name,
        start_branch_name, start_repository)

        OperationService.new(user, self).with_branch(
          branch_name,
          start_branch_name: start_branch_name,
          start_repository: start_repository
        ) do |start_commit|
          index = Gitlab::Git::Index.new(self)
          parents = []

          if start_commit
            index.read_tree(start_commit.rugged_commit.tree)
            parents = [start_commit.sha]
          end

          actions.each { |opts| index.apply(opts.delete(:action), opts) }

          committer = user_to_committer(user)
          author = Gitlab::Git.committer_hash(email: author_email, name: author_name) || committer
          options = {
            tree: index.write_tree,
            message: message,
            parents: parents,
            author: author,
            committer: committer
          }

          create_commit(options)
        end
      end

      def fetch_remote(remote_name = 'origin', env: nil)
        run_git(['fetch', remote_name], env: env).last.zero?
      end

      def gitaly_can_be_merged?(their_commit, our_commit)
        !gitaly_conflicts_client(our_commit, their_commit).conflicts?
      end

      def rugged_can_be_merged?(their_commit, our_commit)
        !rugged.merge_commits(our_commit, their_commit).conflicts?
      end

      def gitlab_projects_error
        raise CommandError, @gitlab_projects.output
      end

      def find_commits_by_message_by_shelling_out(query, ref, path, limit, offset)
        ref ||= root_ref

        args = %W(
          log #{ref} --pretty=%H --skip #{offset}
          --max-count #{limit} --grep=#{query} --regexp-ignore-case
        )
        args = args.concat(%W(-- #{path})) if path.present?

        git_log_results = run_git(args).first.lines

        git_log_results.map { |c| commit(c.chomp) }.compact
      end

      def find_commits_by_message_by_gitaly(query, ref, path, limit, offset)
        gitaly_commit_client
          .commits_by_message(query, revision: ref, path: path, limit: limit, offset: offset)
          .map { |c| commit(c) }
      end

      def last_commit_for_path_by_gitaly(sha, path)
        gitaly_commit_client.last_commit_for_path(sha, path)
      end

      def last_commit_id_for_path_by_shelling_out(sha, path)
        args = %W(rev-list --max-count=1 #{sha} -- #{path})
        run_git_with_timeout(args, Gitlab::Git::Popen::FAST_GIT_PROCESS_TIMEOUT).first.strip
      end

      def rugged_merge_base(from, to)
        rugged.merge_base(from, to)
      rescue Rugged::ReferenceError
        nil
      end

      def rugged_commit_count(ref)
        walker = Rugged::Walker.new(rugged)
        walker.sorting(Rugged::SORT_TOPO | Rugged::SORT_REVERSE)
        oid = rugged.rev_parse_oid(ref)
        walker.push(oid)
        walker.count
      rescue Rugged::ReferenceError
        0
      end

      def rev_list_param(spec)
        spec == :all ? ['--all'] : spec
      end

      def sha_from_ref(ref)
        rev_parse_target(ref).oid
      end

      def calculate_checksum_by_shelling_out
        raise NoRepository unless exists?

        args = %W(--git-dir=#{path} show-ref --heads --tags)
        output, status = run_git(args)

        if status.nil? || !status.zero?
          # Empty repositories return with a non-zero status and an empty output.
          return EMPTY_REPOSITORY_CHECKSUM if output&.empty?

          raise ChecksumError, output
        end

        refs = output.split("\n")

        result = refs.inject(nil) do |checksum, ref|
          value = Digest::SHA1.hexdigest(ref).hex

          if checksum.nil?
            value
          else
            checksum ^ value
          end
        end

        result.to_s(16)
      end

      def build_git_cmd(*args)
        object_directories = alternate_object_directories.join(File::PATH_SEPARATOR)

        env = { 'PWD' => self.path }
        env['GIT_ALTERNATE_OBJECT_DIRECTORIES'] = object_directories if object_directories.present?

        [
          env,
          ::Gitlab.config.git.bin_path,
          *args,
          { chdir: self.path }
        ]
      end

      def git_diff_cmd(old_rev, new_rev)
        old_rev = old_rev == ::Gitlab::Git::BLANK_SHA ? ::Gitlab::Git::EMPTY_TREE_ID : old_rev

        build_git_cmd('diff', old_rev, new_rev, '--raw')
      end

      def git_cat_file_cmd
        format = '%(objectname) %(objectsize) %(rest)'
        build_git_cmd('cat-file', "--batch-check=#{format}")
      end

      def format_git_cat_file_script
        File.expand_path('../support/format-git-cat-file-input', __FILE__)
      end
    end
  end
end
