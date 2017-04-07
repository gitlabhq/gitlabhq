module Gitlab
  module Geo
    class LfsUploader < FileUploader
      def execute
        lfs_object = LfsObject.find_by(id: object_db_id)

        return error unless lfs_object.present?
        return error if message[:checksum] != lfs_object.oid

        unless lfs_object.file.present? && lfs_object.file.exists?
          return error('LFS object does not have a file')
        end

        success(lfs_object.file)
      end
    end
  end
end
