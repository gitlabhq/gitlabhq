# frozen_string_literal: true

module Gitlab
  module Instrumentation
    class Uploads
      UPLOAD_DURATION = :uploaded_file_upload_duration_s
      UPLOADED_FILE_SIZE = :uploaded_file_size_bytes

      def self.track(uploaded_file)
        if ::Gitlab::SafeRequestStore.active?
          ::Gitlab::SafeRequestStore[UPLOAD_DURATION] = uploaded_file.upload_duration
          ::Gitlab::SafeRequestStore[UPLOADED_FILE_SIZE] = uploaded_file.size
        end
      end

      def self.get_upload_duration
        ::Gitlab::SafeRequestStore[UPLOAD_DURATION]
      end

      def self.get_uploaded_file_size
        ::Gitlab::SafeRequestStore[UPLOADED_FILE_SIZE]
      end

      def self.payload
        {
          UPLOAD_DURATION => get_upload_duration,
          UPLOADED_FILE_SIZE => get_uploaded_file_size
        }.compact
      end
    end
  end
end
