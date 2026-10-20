# frozen_string_literal: true

module Gitlab
  module Checks
    class ChangedBlobs
      def initialize(project, revisions, bytes_limit:, with_paths: false)
        @project = project
        @revisions = revisions
        @bytes_limit = bytes_limit
        @with_paths = with_paths
      end

      def execute(timeout:)
        # List all blobs via `ListAllBlobs()` based on the existence of a
        # quarantine directory. If no directory exists, we use `ListBlobs()` instead.
        if ignore_alternate_directories?
          fetch_blobs_from_quarantined_repo(timeout: timeout)
        else
          # We use `--not --all --not revisions` to ensure we only get new blobs.
          project.repository.list_blobs(
            ['--not', '--all', '--not'] + revisions,
            bytes_limit: bytes_limit,
            with_paths: with_paths,
            dynamic_timeout: timeout
          ).to_a
        end
      end

      private

      attr_reader :project, :revisions, :bytes_limit, :with_paths

      def fetch_blobs_from_quarantined_repo(timeout:)
        blobs = project.repository.list_all_blobs(
          bytes_limit: bytes_limit,
          dynamic_timeout: timeout,
          ignore_alternate_object_directories: true
        ).to_a

        # A quarantine directory would generally only contain objects which are actually new but
        # this is unfortunately not guaranteed by Git, so it might be that a push has objects which
        # already exist in the repository. To fix this, we have to filter the blobs that already exist.
        #
        # This is not a silver bullet though, a limitation of this is: a secret could possibly go into
        # a commit in a new branch (`refs/heads/secret`) that gets deleted later on, so the commit becomes
        # unreachable but it is still present in the repository, if the same secret is pushed in the same file
        # or even in a new file, it would be ignored because we filter the blob out because it still "exists".
        #
        # See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/136896#note_1680680116 for more details.

        filter_existing!(blobs)
        populate_paths!(blobs) if with_paths

        blobs
      end

      def filter_existing!(blobs)
        # We check for object existence in the main repository, but the
        # object directory points to the object quarantine. This can be fixed
        # by unsetting it, which will cause us to use the normal repository as
        # indicated by its relative path again.
        gitaly_repo = project.repository.gitaly_repository.dup.tap { |repo| repo.git_object_directory = "" }

        map_blob_id_to_existence = project.repository.gitaly_commit_client.object_existence_map(
          blobs.map(&:id),
          gitaly_repo: gitaly_repo
        )

        # Remove blobs that already exist.
        blobs.reject! { |blob| map_blob_id_to_existence[blob.id] }
      end

      def ignore_alternate_directories?
        git_env = ::Gitlab::Git::HookEnv.all(project.repository.gl_repository)
        git_env['GIT_OBJECT_DIRECTORY_RELATIVE'].present?
      end

      def populate_paths!(blobs)
        # All commits which have been newly introduced via any of the given changes
        commits = project.repository.new_commits(revisions)

        # This Gitaly RPC call performs `git-diff-tree` to get changed paths along with their blob ids
        paths = project.repository.find_changed_paths(commits, merge_commit_diff_mode: :all_parents)

        paths_by_blob_id = paths.group_by(&:new_blob_id)

        # `blobs` variable doesn't contain duplicates; however, different paths can point to the same blob
        # In order to make it memory-efficient, we modify the `blobs` by setting the paths, but if
        # a blob points to more than 1 path, we duplicate this blob and store it into `extra_blobs`.
        extra_blobs = []

        blobs.map! do |blob|
          changed_paths = paths_by_blob_id[blob.id]
          next blob if changed_paths.blank?

          blob.path = changed_paths.first.path

          changed_paths[1..].each do |changed_path|
            extra_blobs << blob.dup.tap { |b| b.path = changed_path.path }
          end

          blob
        end

        # Concat extra blobs to the list of blobs. It doesn't create new array and saves memory
        blobs.concat(extra_blobs)
      end
    end
  end
end
