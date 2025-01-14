# frozen_string_literal: true

require 'tempfile'
require 'forwardable'
require "rubygems/package"

module Gitlab
  module Git
    class Repository
      include Gitlab::Git::RepositoryMirroring
      include Gitlab::Git::WrapsGitalyErrors
      include Gitlab::EncodingHelper
      include Gitlab::Utils::StrongMemoize

      SEARCH_CONTEXT_LINES = 3
      REV_LIST_COMMIT_LIMIT = 2_000
      GITALY_INTERNAL_URL = 'ssh://gitaly/internal.git'
      GITLAB_PROJECTS_TIMEOUT = Gitlab.config.gitlab_shell.git_timeout
      EMPTY_REPOSITORY_CHECKSUM = '0000000000000000000000000000000000000000'

      NoRepository = Class.new(::Gitlab::Git::BaseError)
      CommitNotFound = Class.new(::Gitlab::Git::BaseError)
      RepositoryExists = Class.new(::Gitlab::Git::BaseError)
      InvalidRepository = Class.new(::Gitlab::Git::BaseError)
      InvalidBlobName = Class.new(::Gitlab::Git::BaseError)
      InvalidRef = Class.new(::Gitlab::Git::BaseError)
      GitError = Class.new(::Gitlab::Git::BaseError)
      DeleteBranchError = Class.new(::Gitlab::Git::BaseError)
      TagExistsError = Class.new(::Gitlab::Git::BaseError)
      ChecksumError = Class.new(::Gitlab::Git::BaseError)
      class CreateTreeError < ::Gitlab::Git::BaseError
        attr_reader :error_code

        def initialize(error_code)
          super(self.class.name)

          # The value coming from Gitaly is an uppercase String (e.g., "EMPTY")
          @error_code = error_code.downcase.to_sym
        end
      end

      # Directory name of repo
      attr_reader :name

      # Relative path of repo
      attr_reader :relative_path

      attr_reader :storage, :gl_repository, :gl_project_path, :container

      delegate :list_oversized_blobs, :list_all_blobs, :list_blobs, to: :gitaly_blob_client

      # This remote name has to be stable for all types of repositories that
      # can join an object pool. If it's structure ever changes, a migration
      # has to be performed on the object pools to update the remote names.
      # Else the pool can't be updated anymore and is left in an inconsistent
      # state.
      alias_method :object_pool_remote_name, :gl_repository

      def initialize(storage, relative_path, gl_repository, gl_project_path, container: nil)
        @storage = storage
        @relative_path = relative_path
        @gl_repository = gl_repository
        @gl_project_path = gl_project_path
        @container = container

        @name = @relative_path.split("/").last
      end

      def to_s
        "<#{self.class.name}: #{self.gl_project_path}>"
      end

      # Support Feature Flag Repository actor
      def flipper_id
        "Repository:#{@relative_path}"
      end

      def ==(other)
        other.is_a?(self.class) && [storage, relative_path] == [other.storage, other.relative_path]
      end

      alias_method :eql?, :==

      def hash
        [self.class, storage, relative_path].hash
      end

      # Default branch in the repository
      def root_ref(head_only: false)
        wrapped_gitaly_errors do
          gitaly_ref_client.default_branch_name(head_only: head_only)
        end
      end

      def exists?
        gitaly_repository_client.exists?
      end

      def create_repository(default_branch = nil, object_format: nil)
        wrapped_gitaly_errors do
          gitaly_repository_client.create_repository(default_branch, object_format: object_format)
        rescue GRPC::AlreadyExists => e
          raise RepositoryExists, e.message
        end
      end

      # Returns an Array of branch names
      # sorted by name ASC
      def branch_names
        refs = list_refs([Gitlab::Git::BRANCH_REF_PREFIX])

        refs.map { |ref| Gitlab::Git.branch_name(ref.name) }
      end

      # Returns an Array of Branches
      def branches
        wrapped_gitaly_errors do
          gitaly_ref_client.branches
        end
      end

      # Directly find a branch with a simple name (e.g. master)
      #
      def find_branch(name)
        wrapped_gitaly_errors do
          gitaly_ref_client.find_branch(name)
        end
      rescue Gitlab::Git::AmbiguousRef
        # Gitaly returns "reference is ambiguous" error in case when users request
        # branch "my-branch", when another branch "my-branch/branch" exists.
        # We handle this error here and return nil for this case.
      end

      def find_tag(name)
        wrapped_gitaly_errors do
          gitaly_ref_client.find_tag(name)
        end
      rescue CommandError
        # Gitaly used to return an `Internal` error in case the tag wasn't found, which is being translated to
        # `CommandError` by the wrapper. This has been converted in v15.3.0 to instead return a structured
        # error with a `tag_not_found` error, so rescuing from `Internal` errors can be removed in v15.4.0 and
        # later.
      rescue Gitlab::Git::ReferenceNotFoundError
        # This is the new error returned by `find_tag`, which knows to translate the structured error returned
        # by Gitaly when the tag does not exist.
      end

      def local_branches(sort_by: nil, pagination_params: nil)
        wrapped_gitaly_errors do
          gitaly_ref_client.local_branches(sort_by: sort_by, pagination_params: pagination_params)
        end
      end

      # Returns the number of valid branches
      def branch_count
        branch_names.count
      end

      def remove
        wrapped_gitaly_errors do
          gitaly_repository_client.remove
        end
      rescue NoRepository
        nil
      end

      def replicate(source_repository, partition_hint: "")
        wrapped_gitaly_errors do
          gitaly_repository_client.replicate(source_repository, partition_hint: partition_hint)
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

      # Returns the number of valid tags
      def tag_count
        tag_names.count
      end

      # Returns an Array of tag names
      def tag_names
        refs = list_refs([Gitlab::Git::TAG_REF_PREFIX])

        refs.map { |ref| Gitlab::Git.tag_name(ref.name) }
      end

      # Returns an Array of Tags
      #
      def tags(sort_by: nil, pagination_params: nil)
        wrapped_gitaly_errors do
          gitaly_ref_client.tags(sort_by: sort_by, pagination_params: pagination_params)
        end
      end

      # Returns true if the given ref name exists
      #
      # Ref names must start with `refs/`.
      def ref_exists?(ref_name)
        wrapped_gitaly_errors do
          gitaly_ref_exists?(ref_name)
        end
      end

      # Returns true if the given tag exists
      #
      # name - The name of the tag as a String.
      def tag_exists?(name)
        wrapped_gitaly_errors do
          gitaly_ref_exists?("refs/tags/#{name}")
        end
      end

      # Returns true if the given branch exists
      #
      # name - The name of the branch as a String.
      def branch_exists?(name)
        wrapped_gitaly_errors do
          gitaly_ref_exists?("refs/heads/#{name}")
        end
      end

      # Returns an Array of branch and tag names
      def ref_names
        branch_names + tag_names
      end

      def delete_all_refs_except(prefixes)
        wrapped_gitaly_errors do
          gitaly_ref_client.delete_refs(except_with_prefixes: prefixes)
        end
      end

      def archive_metadata(ref, storage_path, project_path, format = "tar.gz", append_sha:, path: nil)
        ref ||= root_ref

        commit_id = extract_commit_id_from_ref(ref)
        return {} if commit_id.nil?

        commit = Gitlab::Git::Commit.find(self, commit_id)
        return {} if commit.nil?

        prefix = archive_prefix(ref, commit.id, project_path, append_sha: append_sha, path: path)

        {
          'ArchivePrefix' => prefix,
          'ArchivePath' => archive_file_path(storage_path, commit.id, prefix, format),
          'CommitId' => commit.id,
          'GitalyRepository' => gitaly_repository.to_h
        }
      end

      # This is both the filename of the archive (missing the extension) and the
      # name of the top-level member of the archive under which all files go
      def archive_prefix(ref, sha, project_path, append_sha:, path:)
        append_sha = (ref != sha) if append_sha.nil?

        formatted_ref = ref.tr('/', '-')

        prefix_segments = [project_path, formatted_ref]
        prefix_segments << sha if append_sha
        prefix_segments << path.tr('/', '-').gsub(%r{^/|/$}, '') if path

        prefix_segments.join('-')
      end
      private :archive_prefix

      # The full path on disk where the archive should be stored. This is used
      # to cache the archive between requests.
      #
      # The path is a global namespace, so needs to be globally unique. This is
      # achieved by including `gl_repository` in the path.
      #
      # Archives relating to a particular ref when the SHA is not present in the
      # filename must be invalidated when the ref is updated to point to a new
      # SHA. This is achieved by including the SHA in the path.
      #
      # As this is a full path on disk, it is not "cloud native". This should
      # be resolved by either removing the cache, or moving the implementation
      # into Gitaly and removing the ArchivePath parameter from the git-archive
      # senddata response.
      def archive_file_path(storage_path, sha, name, format = "tar.gz")
        # Build file path
        return unless name

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
        File.join(storage_path, self.gl_repository, sha, archive_version_path, file_name)
      end
      private :archive_file_path

      def archive_version_path
        '@v2'
      end
      private :archive_version_path

      # Return repo size in megabytes
      def size
        if Feature.enabled?(:use_repository_info_for_repository_size)
          repository_info_size_megabytes
        else
          kilobytes = gitaly_repository_client.repository_size
          (kilobytes.to_f / 1024).round(2)
        end
      end

      # Return repository recent objects size in mebibytes
      #
      # This differs from the #size method in that it does not include the size of:
      # - stale objects
      # - cruft packs of unreachable objects
      #
      # see: https://gitlab.com/gitlab-org/gitaly/-/blob/257ee33ca268d48c8f99dcbfeaaf7d8b19e07f06/internal/gitaly/service/repository/repository_info.go#L41-62
      def recent_objects_size
        wrapped_gitaly_errors do
          recent_size_in_bytes = gitaly_repository_client.repository_info.objects.recent_size

          Gitlab::Utils.bytes_to_megabytes(recent_size_in_bytes)
        end
      end

      # Return git object directory size in bytes
      def object_directory_size
        gitaly_repository_client.get_object_directory_size.to_f * 1024
      end

      # Build an array of commits.
      #
      # Usage.
      #   repo.log(
      #     ref: 'master',
      #     path: 'app/models',
      #     limit: 10,
      #     offset: 5,
      #     after: Time.new(2016, 4, 21, 14, 32, 10)
      #   )
      def log(options)
        default_options = {
          limit: 10,
          offset: 0,
          path: nil,
          author: nil,
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
          raise ArgumentError, "invalid Repository#log limit: #{limit.inspect}"
        end

        # call Gitaly client to fetch commits, if a NotFound happens we return an empty array
        begin
          wrapped_gitaly_errors do
            gitaly_commit_client.find_commits(options)
          end
        rescue Gitlab::Git::Repository::CommitNotFound
          []
        end
      end

      def new_commits(newrevs)
        wrapped_gitaly_errors do
          gitaly_commit_client.list_new_commits(Array.wrap(newrevs))
        end
      end

      def check_objects_exist(refs)
        wrapped_gitaly_errors do
          gitaly_commit_client.object_existence_map(Array.wrap(refs))
        end
      end

      def new_blobs(newrevs, dynamic_timeout: nil)
        newrevs = Array.wrap(newrevs).reject { |rev| rev.blank? || Gitlab::Git.blank_ref?(rev) }
        return [] if newrevs.empty?

        newrevs = newrevs.uniq.sort

        @new_blobs ||= {}
        @new_blobs[newrevs] ||= blobs(
          ['--not', '--all', '--not'] + newrevs,
          with_paths: true,
          dynamic_timeout: dynamic_timeout
        ).to_a
      end

      # List blobs reachable via a set of revisions. Supports the
      # pseudo-revisions `--not` and `--all`. Uses the minimum of
      # GitalyClient.medium_timeout and dynamic timeout if the dynamic
      # timeout is set, otherwise it'll always use the medium timeout.
      def blobs(revisions, with_paths: false, dynamic_timeout: nil)
        revisions = revisions.reject { |rev| rev.blank? || Gitlab::Git.blank_ref?(rev) }

        return [] if revisions.blank?

        wrapped_gitaly_errors do
          gitaly_blob_client.list_blobs(revisions, limit: REV_LIST_COMMIT_LIMIT,
            with_paths: with_paths, dynamic_timeout: dynamic_timeout)
        end
      end

      def count_commits(options)
        options = process_count_commits_options(options.dup)

        wrapped_gitaly_errors do
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
      end

      # Counts the amount of commits between `from` and `to`.
      def count_commits_between(from, to, options = {})
        count_commits(from: from, to: to, **options)
      end

      # old_rev and new_rev are commit ID's
      # the result of this method is an array of Gitlab::Git::RawDiffChange
      def raw_changes_between(old_rev, new_rev)
        @raw_changes_between ||= {}

        @raw_changes_between[[old_rev, new_rev]] ||=
          begin
            return [] if new_rev.blank? || Gitlab::Git.blank_ref?(new_rev)

            wrapped_gitaly_errors do
              gitaly_repository_client.raw_changes_between(old_rev, new_rev)
                .each_with_object([]) do |msg, arr|
                msg.raw_changes.each { |change| arr << ::Gitlab::Git::RawDiffChange.new(change) }
              end
            end
          end
      rescue ArgumentError => e
        raise Gitlab::Git::Repository::GitError, e
      end

      # Returns the SHA of the most recent common ancestor of +from+ and +to+
      def merge_base(...)
        wrapped_gitaly_errors do
          gitaly_repository_client.find_merge_base(...)
        end
      end

      # Returns true is +from+ is direct ancestor to +to+, otherwise false
      def ancestor?(from, to)
        gitaly_commit_client.ancestor?(from, to)
      end

      def merged_branch_names(branch_names = [])
        return [] unless root_ref

        root_sha = find_branch(root_ref)&.target

        return [] unless root_sha

        branches = wrapped_gitaly_errors do
          gitaly_merged_branch_names(branch_names, root_sha)
        end

        Set.new(branches)
      end

      # Returns an array of DiffBlob objects that represent a diff between
      # two blobs in a repository. For each diff generated, the pre-image and
      # post-image blob IDs should be obtained using `find_changed_paths` method.
      def diff_blobs(...)
        wrapped_gitaly_errors do
          gitaly_diff_client.diff_blobs(...)
        end
      end

      # Return an array of Diff objects that represent the diff
      # between +from+ and +to+.  See Diff::filter_diff_options for the allowed
      # diff options.  The +options+ hash can also include :break_rewrites to
      # split larger rewrites into delete/add pairs.
      def diff(from, to, options = {}, *paths)
        iterator = gitaly_commit_client.diff(from, to, options.merge(paths: paths))

        Gitlab::Git::DiffCollection.new(iterator, options)
      end

      def diff_stats(left_id, right_id)
        if [left_id, right_id].any? { |ref| ref.blank? || Gitlab::Git.blank_ref?(ref) }
          return empty_diff_stats
        end

        stats = wrapped_gitaly_errors do
          gitaly_commit_client.diff_stats(left_id, right_id)
        end

        Gitlab::Git::DiffStatsCollection.new(stats)
      rescue CommandError, TypeError
        empty_diff_stats
      end

      def find_changed_paths(treeish_objects, merge_commit_diff_mode: nil, find_renames: false)
        processed_objects = treeish_objects.compact

        return [] if processed_objects.empty?

        wrapped_gitaly_errors do
          gitaly_commit_client.find_changed_paths(processed_objects, merge_commit_diff_mode: merge_commit_diff_mode, find_renames: find_renames)
        end
      rescue CommandError, TypeError, NoRepository
        []
      end

      # Get refs hash which key is the commit id
      # and value is a Gitlab::Git::Tag or Gitlab::Git::Branch
      # Note that both inherit from Gitlab::Git::Ref
      def refs_hash
        return @refs_hash if @refs_hash

        @refs_hash = Hash.new { |h, k| h[k] = [] }

        (tags + branches).each do |ref|
          next unless ref.target && ref.name && ref.dereferenced_target&.id

          @refs_hash[ref.dereferenced_target.id] << ref.name
        end

        @refs_hash
      end

      # Returns matching refs for OID
      #
      # Limit of 0 means there is no limit.
      def refs_by_oid(oid:, limit: 0, ref_patterns: nil)
        wrapped_gitaly_errors do
          gitaly_ref_client.find_refs_by_oid(oid: oid, limit: limit, ref_patterns: ref_patterns) || []
        end
      rescue CommandError, TypeError, NoRepository
        []
      end

      # Returns url for submodule
      #
      # Ex.
      #   @repository.submodule_url_for('master', 'rack')
      #   # => git@localhost:rack.git
      #
      def submodule_url_for(ref, path)
        wrapped_gitaly_errors do
          gitaly_submodule_url_for(ref, path)
        end
      end

      # Returns path to url mappings for submodules
      #
      # Ex.
      #   @repository.submodule_urls_for('master')
      #   # => { 'rack' => 'git@localhost:rack.git' }
      #
      def submodule_urls_for(ref)
        wrapped_gitaly_errors do
          gitaly_submodule_urls_for(ref)
        end
      end

      # Return total commits count accessible from passed ref
      def commit_count(ref)
        wrapped_gitaly_errors do
          gitaly_commit_client.commit_count(ref)
        end
      end

      # Return total diverging commits count
      def diverging_commit_count(from, to, max_count: 0)
        wrapped_gitaly_errors do
          gitaly_commit_client.diverging_commit_count(from, to, max_count: max_count)
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
        wrapped_gitaly_errors do
          gitaly_operation_client.user_create_branch(branch_name, user, target)
        end
      end

      def add_tag(tag_name, user:, target:, message: nil)
        wrapped_gitaly_errors do
          gitaly_operation_client.add_tag(tag_name, user, target, message)
        end
      end

      def update_branch(branch_name, user:, newrev:, oldrev:)
        wrapped_gitaly_errors do
          gitaly_operation_client.user_update_branch(branch_name, user, newrev, oldrev)
        end
      end

      def rm_branch(branch_name, user:, target_sha: nil)
        wrapped_gitaly_errors do
          gitaly_operation_client.user_delete_branch(branch_name, user, target_sha: target_sha)
        end
      end

      def rm_tag(tag_name, user:)
        wrapped_gitaly_errors do
          gitaly_operation_client.rm_tag(tag_name, user)
        end
      end

      def merge_to_ref(user, **kwargs)
        wrapped_gitaly_errors do
          gitaly_operation_client.user_merge_to_ref(user, **kwargs)
        end
      end

      def merge(user, source_sha:, target_branch:, message:, target_sha: nil, &block)
        wrapped_gitaly_errors do
          gitaly_operation_client.user_merge_branch(user,
            source_sha: source_sha,
            target_branch: target_branch,
            message: message,
            target_sha: target_sha,
            &block)
        end
      end

      def ff_merge(user, source_sha:, target_branch:, target_sha: nil)
        wrapped_gitaly_errors do
          gitaly_operation_client.user_ff_branch(user,
            source_sha: source_sha,
            target_branch: target_branch,
            target_sha: target_sha)
        end
      end

      def revert(user:, commit:, branch_name:, message:, start_branch_name:, start_repository:, dry_run: false)
        args = {
          user: user,
          commit: commit,
          branch_name: branch_name,
          message: message,
          start_branch_name: start_branch_name,
          start_repository: start_repository,
          dry_run: dry_run
        }

        wrapped_gitaly_errors do
          gitaly_operation_client.user_revert(**args)
        end
      end

      def cherry_pick(...)
        wrapped_gitaly_errors do
          gitaly_operation_client.user_cherry_pick(...)
        end
      end

      def update_submodule(user:, submodule:, commit_sha:, message:, branch:)
        args = {
          user: user,
          submodule: submodule,
          commit_sha: commit_sha,
          branch: branch,
          message: message
        }

        wrapped_gitaly_errors do
          gitaly_operation_client.user_update_submodule(**args)
        end
      end

      # Delete the specified branch from the repository
      # Note: No Git hooks are executed for this action
      def delete_branch(branch_name)
        branch_name = "#{Gitlab::Git::BRANCH_REF_PREFIX}#{branch_name}" unless branch_name.start_with?("refs/")

        delete_refs(branch_name)
      rescue CommandError => e
        raise DeleteBranchError, e
      end

      def async_delete_refs(*refs)
        raise "async_delete_refs only supports project repositories" unless container.is_a?(Project)

        records = refs.map do |ref|
          BatchedGitRefUpdates::Deletion.new(project_id: container.id, ref: ref, created_at: Time.current, updated_at: Time.current)
        end

        BatchedGitRefUpdates::Deletion.bulk_insert!(records)
      end

      # Update a list of references from X -> Y
      #
      # Ref list is expected to be an array of hashes in the form:
      # old_sha:
      # new_sha
      # reference:
      #
      # When new_sha is Gitlab::Git::SHA1_BLANK_SHA, then this will be deleted
      def update_refs(ref_list)
        wrapped_gitaly_errors do
          gitaly_ref_client.update_refs(ref_list: ref_list) if ref_list.any?
        end
      end

      def delete_refs(...)
        wrapped_gitaly_errors do
          gitaly_delete_refs(...)
        end
      end

      # Create a new branch named **ref+ based on **stat_point+, HEAD by default
      # Note: No Git hooks are executed for this action
      #
      # Examples:
      #   create_branch("feature")
      #   create_branch("other-feature", "master")
      def create_branch(ref, start_point = "HEAD")
        write_ref(ref, start_point)
      end

      def find_remote_root_ref(remote_url, authorization = nil)
        return unless remote_url.present?

        wrapped_gitaly_errors do
          gitaly_remote_client.find_remote_root_ref(remote_url, authorization)
        end
      end

      # Returns result like "git ls-files" , recursive and full file path
      #
      # Ex.
      #   repo.ls_files('master')
      #
      def ls_files(ref)
        gitaly_commit_client.ls_files(ref)
      end

      def info_attributes
        return @info_attributes if @info_attributes

        content = gitaly_repository_client.info_attributes
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

      # Returns parsed .gitattributes for a given ref
      #
      # This only parses the root .gitattributes file,
      # it does not traverse subfolders to find additional .gitattributes files
      #
      # This method is around 30 times slower than `attributes`, which uses
      # `$GIT_DIR/info/attributes`. Consider caching AttributesAtRefParser
      # and reusing that for multiple calls instead of this method.
      def attributes_at(ref)
        AttributesAtRefParser.new(self, ref)
      end

      def languages(ref = nil)
        wrapped_gitaly_errors do
          gitaly_commit_client.languages(ref)
        end
      end

      def license
        wrapped_gitaly_errors do
          response = gitaly_repository_client.find_license

          break nil if response.license_short_name.empty?

          ::Gitlab::Git::DeclaredLicense.new(key: response.license_short_name,
            name: response.license_name,
            nickname: response.license_nickname.presence,
            url: response.license_url.presence,
            path: response.license_path)
        end
      rescue Licensee::InvalidLicense => e
        Gitlab::ErrorTracking.track_exception(e)
        nil
      end

      def fetch_source_branch!(source_repository, source_branch, local_ref)
        wrapped_gitaly_errors do
          gitaly_repository_client.fetch_source_branch(source_repository, source_branch, local_ref)
        end
      end

      def compare_source_branch(target_branch_name, source_repository, source_branch_name, straight:)
        CrossRepo.new(source_repository, self).execute(target_branch_name) do |target_commit_id|
          Gitlab::Git::Compare.new(
            source_repository,
            target_commit_id,
            source_branch_name,
            straight: straight
          )
        end
      end

      def write_ref(ref_path, ref, old_ref: nil)
        ref_path = "#{Gitlab::Git::BRANCH_REF_PREFIX}#{ref_path}" unless ref_path.start_with?("refs/") || ref_path == "HEAD"

        wrapped_gitaly_errors do
          gitaly_repository_client.write_ref(ref_path, ref, old_ref)
        end
      end

      # peel_tags slows down the request by a factor of 3-4
      def list_refs(...)
        wrapped_gitaly_errors do
          gitaly_ref_client.list_refs(...)
        end
      end

      # Refactoring aid; allows us to copy code from app/models/repository.rb
      def commit(ref = 'HEAD')
        Gitlab::Git::Commit.find(self, ref)
      end

      def empty?
        !has_visible_content?
      end

      # Fetch remote for repository
      #
      # remote - remote name
      # url - URL of the remote to fetch. `remote` is not used in this case.
      # refmap - if url is given, determines which references should get fetched where
      # ssh_auth - SSH known_hosts data and a private key to use for public-key authentication
      # forced - should we use --force flag?
      # no_tags - should we use --no-tags flag?
      # prune - should we use --prune flag?
      # check_tags_changed - should we ask gitaly to calculate whether any tags changed?
      # resolved_address - resolved IP address for provided URL
      def fetch_remote( # rubocop:disable Metrics/ParameterLists
        url,
        refmap: nil, ssh_auth: nil, forced: false, no_tags: false, prune: true,
        check_tags_changed: false, http_authorization_header: "", resolved_address: "")
        wrapped_gitaly_errors do
          gitaly_repository_client.fetch_remote(
            url,
            refmap: refmap,
            ssh_auth: ssh_auth,
            forced: forced,
            no_tags: no_tags,
            prune: prune,
            check_tags_changed: check_tags_changed,
            timeout: GITLAB_PROJECTS_TIMEOUT,
            http_authorization_header: http_authorization_header,
            resolved_address: resolved_address
          )
        end
      end

      def import_repository(url, http_authorization_header: '', mirror: false, resolved_address: '')
        raise ArgumentError, "don't use disk paths with import_repository: #{url.inspect}" if url.start_with?('.', '/')

        wrapped_gitaly_errors do
          gitaly_repository_client.import_repository(url, http_authorization_header: http_authorization_header, mirror: mirror, resolved_address: resolved_address)
        end
      end

      def blob_at(sha, path, limit: Gitlab::Git::Blob::MAX_DATA_DISPLAY_SIZE)
        Gitlab::Git::Blob.find(self, sha, path, limit: limit) unless Gitlab::Git.blank_ref?(sha)
      end

      # Items should be of format [[commit_id, path], [commit_id1, path1]]
      def batch_blobs(items, blob_size_limit: Gitlab::Git::Blob::MAX_DATA_DISPLAY_SIZE)
        Gitlab::Git::Blob.batch(self, items, blob_size_limit: blob_size_limit)
      end

      def fsck
        msg, status = gitaly_repository_client.fsck

        raise GitError, "Could not fsck repository: #{msg}" unless status == 0
      end

      def create_from_bundle(bundle_path)
        # It's important to check that the linked-to file is actually a valid
        # .bundle file as it is passed to `git clone`, which may otherwise
        # interpret it as a pointer to another repository
        ::Gitlab::Git::BundleFile.check!(bundle_path)

        gitaly_repository_client.create_from_bundle(bundle_path)
      end

      def rebase(user, rebase_id, branch:, branch_sha:, remote_repository:, remote_branch:, push_options: [], &block)
        wrapped_gitaly_errors do
          gitaly_operation_client.rebase(
            user,
            rebase_id,
            branch: branch,
            branch_sha: branch_sha,
            remote_repository: remote_repository,
            remote_branch: remote_branch,
            push_options: push_options,
            &block
          )
        end
      end

      def rebase_to_ref(user, source_sha:, target_ref:, first_parent_ref:, expected_old_oid: "")
        wrapped_gitaly_errors do
          gitaly_operation_client.user_rebase_to_ref(
            user,
            source_sha: source_sha,
            target_ref: target_ref,
            first_parent_ref: first_parent_ref,
            expected_old_oid: expected_old_oid
          )
        end
      end

      def squash(user, start_sha:, end_sha:, author:, message:)
        wrapped_gitaly_errors do
          gitaly_operation_client.user_squash(user, start_sha, end_sha, author, message)
        end
      end

      def bundle_to_disk(save_path)
        wrapped_gitaly_errors do
          gitaly_repository_client.create_bundle(save_path)
        end

        true
      end

      # Creates a commit
      #
      # @param [User] user The committer of the commit.
      # @param [String] branch_name: The name of the branch to be created/updated.
      # @param [String] message: The commit message.
      # @param [Array<Hash>] actions: An array of files to be added/updated/removed.
      # @option actions: [Symbol] :action One of :create, :create_dir, :update, :move, :delete, :chmod
      # @option actions: [String] :file_path The path of the file or directory being added/updated/removed.
      # @option actions: [String] :previous_path The path of the file being moved. Only used for the :move action.
      # @option actions: [String,IO] :content The file content for :create or :update
      # @option actions: [String] :encoding One of text, base64
      # @option actions: [Boolean] :execute_filemode True sets the executable filemode on the file.
      # @option actions: [Boolean] :infer_content True uses the existing file contents instead of using content on move.
      # @param [String] author_email: The authors email, if unspecified the committers email is used.
      # @param [String] author_name: The authors name, if unspecified the committers name is used.
      # @param [String] start_branch_name: The name of the branch to be used as the parent of the commit. Only used if start_sha: is unspecified.
      # @param [String] start_sha: The sha to be used as the parent of the commit.
      # @param [Gitlab::Git::Repository] start_repository: The repository that contains the start branch or sha. Defaults to use this repository.
      # @param [Boolean] force: Force update the branch.
      # @param [String] target_sha: The latest sha of the target branch (optional). Used to prevent races in updates between different clients.
      # @return [Gitlab::Git::OperationService::BranchUpdate]
      #
      # rubocop:disable Metrics/ParameterLists
      def commit_files(
        user, branch_name:, message:, actions:,
        author_email: nil, author_name: nil,
        start_branch_name: nil, start_sha: nil, start_repository: nil,
        force: false, sign: true, target_sha: nil)

        wrapped_gitaly_errors do
          gitaly_operation_client.user_commit_files(user, branch_name,
            message, actions, author_email, author_name, start_branch_name,
            start_repository, force, start_sha, sign, target_sha)
        end
      end
      # rubocop:enable Metrics/ParameterLists

      def disconnect_alternates
        wrapped_gitaly_errors do
          gitaly_repository_client.disconnect_alternates
        end
      end

      def gitaly_repository
        Gitlab::GitalyClient::Util.repository(@storage, @relative_path, @gl_repository, @gl_project_path)
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

      def gitaly_diff_client
        @gitaly_diff_client ||= Gitlab::GitalyClient::DiffService.new(self)
      end

      def gitaly_conflicts_client(our_commit_oid, their_commit_oid)
        Gitlab::GitalyClient::ConflictsService.new(self, our_commit_oid, their_commit_oid)
      end

      def praefect_info_client
        @praefect_info_client ||= Gitlab::GitalyClient::PraefectInfoService.new(self)
      end

      def gitaly_analysis_client
        @gitaly_analysis_client ||= Gitlab::GitalyClient::AnalysisService.new(self)
      end

      def branch_names_contains_sha(sha, limit: 0)
        gitaly_ref_client.branch_names_contains_sha(sha, limit: limit)
      end

      def tag_names_contains_sha(sha, limit: 0)
        gitaly_ref_client.tag_names_contains_sha(sha, limit: limit)
      end

      def search_files_by_content(query, ref, options = {})
        return [] if empty? || query.blank?

        safe_query = Regexp.escape(query)
        ref ||= root_ref

        gitaly_repository_client.search_files_by_content(ref, safe_query, options)
      end

      def can_be_merged?(source_sha, target_branch)
        if target_sha = find_branch(target_branch)&.target
          !gitaly_conflicts_client(source_sha, target_sha).conflicts?
        else
          false
        end
      end

      def search_files_by_name(query, ref, limit: 0, offset: 0)
        safe_query = query.sub(%r{^/*}, "")
        ref ||= root_ref

        return [] if empty? || safe_query.blank?

        gitaly_repository_client.search_files_by_name(ref, safe_query, limit: limit, offset: offset).map do |file|
          Gitlab::EncodingHelper.encode_utf8(file)
        end
      end

      def search_files_by_regexp(filter, ref = 'HEAD', limit: 0, offset: 0)
        gitaly_repository_client.search_files_by_regexp(ref, filter, limit: limit, offset: offset).map do |file|
          Gitlab::EncodingHelper.encode_utf8(file)
        end
      end

      def find_commits_by_message(query, ref, path, limit, offset)
        wrapped_gitaly_errors do
          gitaly_commit_client
            .commits_by_message(query, revision: ref, path: path, limit: limit, offset: offset)
            .map { |c| commit(c) }
        end
      end

      def list_commits_by(query, ref, author: nil, before: nil, after: nil, limit: 1000)
        params = {
          author: author,
          ignore_case: true,
          commit_message_patterns: query,
          before: before,
          after: after,
          reverse: false,
          pagination_params: { limit: limit }
        }

        wrapped_gitaly_errors do
          gitaly_commit_client
            .list_commits([ref], params)
            .map { |c| commit(c) }
        end
      end

      def list_last_commits_for_tree(sha, path, offset: 0, limit: 25, literal_pathspec: false)
        wrapped_gitaly_errors do
          gitaly_commit_client.list_last_commits_for_tree(sha, path, offset: offset, limit: limit, literal_pathspec: literal_pathspec)
        end
      end

      def list_commits_by_ref_name(refs)
        wrapped_gitaly_errors do
          gitaly_commit_client.list_commits_by_ref_name(refs)
        end
      end

      def last_commit_for_path(sha, path, literal_pathspec: false)
        wrapped_gitaly_errors do
          gitaly_commit_client.last_commit_for_path(sha, path, literal_pathspec: literal_pathspec)
        end
      end

      def checksum
        # The exists? RPC is much cheaper, so we perform this request first
        raise NoRepository, "Repository does not exist" unless exists?

        gitaly_repository_client.calculate_checksum
      rescue GRPC::NotFound
        raise NoRepository # Guard against data races.
      end

      def replicas
        wrapped_gitaly_errors do
          praefect_info_client.replicas
        end
      end

      def get_patch_id(old_revision, new_revision)
        wrapped_gitaly_errors do
          gitaly_commit_client.get_patch_id(old_revision, new_revision)
        end
      end

      def object_pool
        wrapped_gitaly_errors do
          gitaly_repository_client.object_pool.object_pool
        end
      end

      # Note: this problem should be addressed in https://gitlab.com/gitlab-org/gitlab/-/issues/441770
      # Gitlab::Git::Repository shouldn't call Repository directly
      # Instead empty_tree_id value should be passed to Gitaly client
      # via method arguments
      def empty_tree_id
        container.repository.empty_tree_id
      end

      def object_format
        wrapped_gitaly_errors do
          gitaly_repository_client.object_format.format
        end
      end

      def get_file_attributes(revision, file_paths, attributes)
        wrapped_gitaly_errors do
          gitaly_repository_client
            .get_file_attributes(revision, file_paths, attributes)
            .attribute_infos
            .map(&:to_h)
        end
      end

      # rubocop: disable CodeReuse/ActiveRecord -- not an active record operation
      def detect_generated_files(base, head, changed_paths)
        return Set.new if changed_paths.blank?

        # We only display diffs upto the diff_max_files size so we can avoid
        # checking the rest if it exceeds the limit.
        changed_paths = changed_paths.take(Gitlab::CurrentSettings.diff_max_files)

        # Check .gitattributes overrides first
        checked_files = get_file_attributes(
          base,
          changed_paths.map(&:path),
          Gitlab::Git::ATTRIBUTE_OVERRIDES[:generated]
        ).map { |attrs| { path: attrs[:path], generated: attrs[:value] == "set" } }

        # Check automatic generated file detection for the remaining paths
        overridden_paths = checked_files.pluck(:path)
        remainder = changed_paths.reject { |changed_path| overridden_paths.include?(changed_path.path) }
        checked_files += check_blobs_generated(base, head, remainder) if remainder.present?

        checked_files
          .select { |attrs| attrs[:generated] }
          .pluck(:path)
          .to_set

      rescue Gitlab::Git::CommandError, Gitlab::Git::ResourceExhaustedError => e
        # An exception can be raised due to an unknown revision or paths.
        # Gitlab::Git::ResourceExhaustedError could be raised if the request payload is too large.
        Gitlab::ErrorTracking.track_exception(
          e,
          gl_project_path: @gl_project_path,
          base: base,
          head: head,
          paths_count: changed_paths.count,
          paths_bytesize: changed_paths.map(&:path).join.bytesize
        )

        Set.new
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def diffs_by_changed_paths(diff_refs, offset, batch_size = 30)
        changed_paths = find_changed_paths(
          [Gitlab::Git::DiffTree.new(diff_refs.base_sha, diff_refs.head_sha)],
          find_renames: true
        )

        changed_paths.drop(offset).each_slice(batch_size) do |batched_changed_paths|
          blob_pairs = batched_changed_paths.reject(&:submodule_change?).map do |changed_path|
            Gitaly::DiffBlobsRequest::BlobPair.new(
              left_blob: changed_path.old_blob_id,
              right_blob: changed_path.new_blob_id
            )
          end

          yield diff_files_by_blob_pairs(blob_pairs, batched_changed_paths, diff_refs)
        end
      end

      private

      def diff_files_by_blob_pairs(blob_pairs, changed_paths, diff_refs)
        non_submodule_paths = changed_paths.reject(&:submodule_change?)
        diff_blobs = diff_blobs(blob_pairs, patch_bytes_limit: Gitlab::Git::Diff.patch_hard_limit_bytes)

        changed_diff_blobs = diff_blobs.zip(non_submodule_paths)
        diff_blob_lookup = changed_diff_blobs.to_h { |diff_blob, path| [path.path, diff_blob] }

        changed_paths.map do |changed_path|
          if changed_path.submodule_change?
            create_diff(changed_path, diff_refs, diff: generate_submodule_diff(changed_path))
          else
            diff_blob = diff_blob_lookup[changed_path.path]
            create_diff(changed_path, diff_refs, diff: diff_blob.patch, too_large: diff_blob.over_patch_bytes_limit)
          end
        end
      end

      def create_diff(changed_path, diff_refs, options = {})
        diff_options = {
          new_path: changed_path.path,
          old_path: changed_path.old_path,
          a_mode: changed_path.old_mode,
          b_mode: changed_path.new_mode,
          new_file: changed_path.new_file?,
          renamed_file: changed_path.renamed_file?,
          deleted_file: changed_path.deleted_file?
        }.merge(options)

        diff = Gitlab::Git::Diff.new(diff_options)

        Gitlab::Diff::File.new(
          diff,
          repository: container.repository,
          diff_refs: diff_refs
        )
      end

      def generate_submodule_diff(changed_path)
        diff_lines = []
        diff_lines << "- Subproject commit #{changed_path.old_blob_id}" if changed_path.deleted_file? || changed_path.modified_file?
        diff_lines << "+ Subproject commit #{changed_path.new_blob_id}" if changed_path.new_file? || changed_path.modified_file?

        diff_lines.join("\n")
      end

      def check_blobs_generated(base, head, changed_paths)
        wrapped_gitaly_errors do
          gitaly_analysis_client.check_blobs_generated(base, head, changed_paths)
        end
      end

      def repository_info_size_megabytes
        bytes = gitaly_repository_client.repository_info.size

        Gitlab::Utils.bytes_to_megabytes(bytes).round(2)
      end

      def empty_diff_stats
        Gitlab::Git::DiffStatsCollection.new([])
      end

      def uncached_has_local_branches?
        wrapped_gitaly_errors do
          gitaly_repository_client.has_local_branches?
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

      def gitaly_submodule_url_for(ref, path)
        # We don't care about the contents so 1 byte is enough. Can't request 0 bytes, 0 means unlimited.
        commit_object = gitaly_commit_client.tree_entry(ref, path, 1)

        return unless commit_object && commit_object.type == :COMMIT

        urls = gitaly_submodule_urls_for(ref)
        urls && urls[path]
      end

      def gitaly_submodule_urls_for(ref)
        gitmodules = gitaly_commit_client.tree_entry(ref, '.gitmodules', Gitlab::Git::Blob::MAX_DATA_DISPLAY_SIZE)
        return unless gitmodules

        submodules = GitmodulesParser.new(gitmodules.data).parse
        submodules.transform_values { |submodule| submodule['url'] }
      end

      # Returns true if the given ref name exists
      #
      # Ref names must start with `refs/`.
      def gitaly_ref_exists?(ref_name)
        gitaly_ref_client.ref_exists?(ref_name)
      end

      def gitaly_delete_refs(*ref_names)
        gitaly_ref_client.delete_refs(refs: ref_names) if ref_names.any?
      end

      # The order is based on git priority to resolve ambiguous references
      #
      # `git show <ref>`
      #
      # In case of name clashes, it uses this order:
      # 1. Commit
      # 2. Tag
      # 3. Branch
      def extract_commit_id_from_ref(ref)
        return ref if Gitlab::Git.commit_id?(ref)

        tag = find_tag(ref)
        return tag.dereferenced_target.sha if tag

        branch = find_branch(ref)
        return branch.dereferenced_target.sha if branch

        ref
      end
    end
  end
end
