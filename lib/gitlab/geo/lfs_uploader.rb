module Gitlab
  module Geo
    class LfsUploader < FileUploader
      def execute
        lfs_object = LfsObject.find(object_db_id)

        return error unless lfs_object.present?
        return error if message[:sha256] != lfs_object.oid

        unless lfs_object.file.present? && lfs_object.file.exists?
          return error('LFS object does not have a file')
        end

        success(lfs_object.file)
      end
    end
  end
end
