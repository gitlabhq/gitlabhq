module Gitlab
  module Verify
    class LfsObjects < BatchVerifier
      def name
        'LFS objects'
      end

      def describe(object)
        "LFS object: #{object.oid}"
      end

      private

      def relation
        LfsObject.with_files_stored_locally
      end

      def expected_checksum(lfs_object)
        lfs_object.oid
      end

      def actual_checksum(lfs_object)
        LfsObject.calculate_oid(lfs_object.file.path)
      end
    end
  end
end
