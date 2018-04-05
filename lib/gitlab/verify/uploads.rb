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

      def relation
        Upload.with_files_stored_locally
      end

      def expected_checksum(upload)
        upload.checksum
      end

      def actual_checksum(upload)
        Upload.hexdigest(upload.absolute_path)
      end
    end
  end
end
