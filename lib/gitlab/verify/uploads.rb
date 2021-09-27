# frozen_string_literal: true

module Gitlab
  module Verify
    class Uploads < BatchVerifier
      def name
        'Uploads'
      end

      def describe(object)
        "Upload: #{object.id}"
      end

      private

      # rubocop: disable CodeReuse/ActiveRecord
      def all_relation
        Upload.all.preload(:model)
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def local?(upload)
        upload.local?
      end

      def expected_checksum(upload)
        upload.checksum
      end

      def actual_checksum(upload)
        Upload.sha256_hexdigest(upload.absolute_path)
      end

      def remote_object_exists?(upload)
        upload.retrieve_uploader.file.exists?
      end
    end
  end
end
