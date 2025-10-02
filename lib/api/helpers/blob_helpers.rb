# frozen_string_literal: true

module API
  module Helpers
    module BlobHelpers
      extend Grape::API::Helpers

      MAX_BLOB_SIZE = 10.megabytes
      LARGE_BLOB_THROTTLED_ERROR = <<~ERROR.freeze
        The requested blob is over the threshold size of #{MAX_BLOB_SIZE}.
        Access this blob using '/projects/:id/repository/blobs/:sha/raw' to avoid this error.
      ERROR

      LARGE_FILE_THROTTLED_ERROR = <<~ERROR.freeze
        The requested blob is over the threshold size of #{MAX_BLOB_SIZE}.
        Access this blob using '/projects/:id/repository/files/:file_path/raw' to avoid this error.
      ERROR

      def check_rate_limit_for_blob(blob, endpoint = nil)
        return unless blob
        return unless blob.size > Helpers::BlobHelpers::MAX_BLOB_SIZE

        check_rate_limit!(:large_blob_download, scope: [user_project], message: error_msg(endpoint))
      end

      private

      def error_msg(endpoint)
        case endpoint
        when :repository_files
          Helpers::BlobHelpers::LARGE_FILE_THROTTLED_ERROR
        else
          Helpers::BlobHelpers::LARGE_BLOB_THROTTLED_ERROR
        end
      end
    end
  end
end
