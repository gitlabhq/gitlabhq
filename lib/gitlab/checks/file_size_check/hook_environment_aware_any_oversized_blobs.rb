# frozen_string_literal: true

module Gitlab
  module Checks
    module FileSizeCheck
      class HookEnvironmentAwareAnyOversizedBlobs
        def initialize(project:, changes:, file_size_limit_megabytes:)
          @project = project
          @repository = project.repository
          @changes = changes
          @file_size_limit_megabytes = file_size_limit_megabytes
        end

        def find(timeout: nil)
          if ignore_alternate_directories?
            oversized_blobs(timeout: timeout)
          else
            any_oversize_blobs.find(timeout: timeout)
          end
        end

        private

        attr_reader :project, :repository, :changes, :file_size_limit_megabytes

        def oversized_blobs(timeout: nil)
          oversized_blobs = repository.list_oversized_blobs(bytes_limit: 0, dynamic_timeout: timeout,
            ignore_alternate_object_directories: true, file_size_limit_megabytes: file_size_limit_megabytes).to_a
          filter_existing(oversized_blobs)
        end

        def filter_existing(blobs)
          gitaly_repo = repository.gitaly_repository.dup.tap { |repo| repo.git_object_directory = "" }

          map_blob_id_to_existence = repository.gitaly_commit_client.object_existence_map(blobs.map(&:id),
            gitaly_repo: gitaly_repo)

          blobs.reject { |blob| map_blob_id_to_existence[blob.id].present? }
        end

        def ignore_alternate_directories?
          git_env = ::Gitlab::Git::HookEnv.all(repository.gl_repository)

          git_env['GIT_OBJECT_DIRECTORY_RELATIVE'].present?
        end

        def any_oversize_blobs
          AnyOversizedBlobs.new(project: project, changes: changes,
            file_size_limit_megabytes: file_size_limit_megabytes)
        end
      end
    end
  end
end
