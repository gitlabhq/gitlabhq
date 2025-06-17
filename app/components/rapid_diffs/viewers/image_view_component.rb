# frozen_string_literal: true

module RapidDiffs
  module Viewers
    class ImageViewComponent < ViewerComponent
      include TreeHelper

      def self.viewer_name
        'image'
      end

      def image_data
        {
          old_path: diff_file_old_blob_raw_url,
          new_path: diff_file_blob_raw_url,
          old_size: @diff_file.old_blob&.size,
          new_size: @diff_file.new_blob&.size,
          diff_mode: diff_mode
        }
      end

      def diff_file_old_blob_raw_url
        sha = @diff_file.old_content_sha
        return unless sha

        project_raw_url(
          @diff_file.repository.project,
          tree_join(@diff_file.old_content_sha, @diff_file.old_path),
          only_path: true
        )
      end

      def diff_file_blob_raw_url
        project_raw_url(
          @diff_file.repository.project,
          tree_join(@diff_file.content_sha, @diff_file.file_path),
          only_path: true
        )
      end

      def diff_mode
        return 'new' if @diff_file.new_file?
        return 'deleted' if @diff_file.deleted_file?
        return 'renamed' if @diff_file.renamed_file?
        return 'mode_changed' if @diff_file.mode_changed?

        'replaced'
      end
    end
  end
end
