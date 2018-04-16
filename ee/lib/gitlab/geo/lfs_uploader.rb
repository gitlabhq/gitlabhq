module Gitlab
  module Geo
    # This class is responsible for:
    #   * Finding an LfsObject record
    #   * Returning the necessary response data to send the file back
    #
    # TODO: Rearrange things so this class does not inherit from FileUploader
    class LfsUploader < FileUploader
      def execute
        lfs_object = LfsObject.find_by(id: object_db_id)

        return error('LFS object not found') unless lfs_object
        return error('LFS object not found') if message[:checksum] != lfs_object.oid

        unless lfs_object.file.present? && lfs_object.file.exists?
          log_error("Could not upload LFS object because it does not have a file", id: lfs_object.id)

          return file_not_found(lfs_object)
        end

        success(lfs_object.file)
      end
    end
  end
end
