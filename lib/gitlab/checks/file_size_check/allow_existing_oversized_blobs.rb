# frozen_string_literal: true

module Gitlab
  module Checks
    module FileSizeCheck
      class AllowExistingOversizedBlobs
        def initialize(project:, changes:, file_size_limit_megabytes:)
          @project = project
          @changes = changes
          @oldrevs = changes.pluck(:oldrev).compact # rubocop:disable CodeReuse/ActiveRecord just plucking from an array
          @file_size_limit_megabytes = file_size_limit_megabytes
        end

        def find(timeout: nil)
          oversize_blobs = any_oversize_blobs.find(timeout: timeout)

          return oversize_blobs unless oldrevs.present?

          revs_paths = oldrevs.product(oversize_blobs.map(&:path))
          existing_blobs = project.repository.blobs_at(revs_paths, blob_size_limit: 1)
          map_existing_path_to_size = existing_blobs.group_by(&:path).transform_values { |blobs| blobs.map(&:size).max }

          # return blobs that are going to be over the limit that were previously within the limit
          oversize_blobs.select { |blob| map_existing_path_to_size.fetch(blob.path, 0) <= file_size_limit_megabytes }
        end

        private

        attr_reader :project, :changes, :newrevs, :oldrevs, :file_size_limit_megabytes

        def any_oversize_blobs
          AnyOversizedBlobs.new(project: project, changes: changes,
            file_size_limit_megabytes: file_size_limit_megabytes)
        end
      end
    end
  end
end
