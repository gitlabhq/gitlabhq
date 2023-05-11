# frozen_string_literal: true

module Gitlab
  module Instrumentation
    class Uploads
      UPLOAD_DURATION = :uploaded_file_upload_duration_s
      UPLOADED_FILE_SIZE = :uploaded_file_size_bytes

      InstrumentationStorage = ::Gitlab::Instrumentation::Storage

      def self.track(uploaded_file)
        if InstrumentationStorage.active?
          InstrumentationStorage[UPLOAD_DURATION] = uploaded_file.upload_duration
          InstrumentationStorage[UPLOADED_FILE_SIZE] = uploaded_file.size
        end
      end

      def self.get_upload_duration
        InstrumentationStorage[UPLOAD_DURATION]
      end

      def self.get_uploaded_file_size
        InstrumentationStorage[UPLOADED_FILE_SIZE]
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
