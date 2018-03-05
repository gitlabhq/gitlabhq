module Gitlab
  module Verify
    class Uploads < BatchVerifier
<<<<<<< HEAD
      prepend ::EE::Gitlab::Verify::Uploads

=======
>>>>>>> upstream/master
      def name
        'Uploads'
      end

      def describe(object)
        "Upload: #{object.id}"
      end

      private

      def relation
        Upload.all
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
