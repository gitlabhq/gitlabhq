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

      def all_relation
        Upload.all.preload(:model)
      end

      def local?(upload)
        upload.local?
      end

      def expected_checksum(upload)
        upload.checksum
      end

      def actual_checksum(upload)
        Upload.hexdigest(upload.absolute_path)
      end

      def remote_object_exists?(upload)
        upload.build_uploader.file.exists?
      end
    end
  end
end
