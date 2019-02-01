# frozen_string_literal: true

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

      def all_relation
        LfsObject.all
      end

      def local?(lfs_object)
        lfs_object.local_store?
      end

      def expected_checksum(lfs_object)
        lfs_object.oid
      end

      def actual_checksum(lfs_object)
        LfsObject.calculate_oid(lfs_object.file.path)
      end

      def remote_object_exists?(lfs_object)
        lfs_object.file.file.exists?
      end
    end
  end
end
