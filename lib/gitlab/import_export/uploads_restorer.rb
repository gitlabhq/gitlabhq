module Gitlab
  module ImportExport
    class UploadsRestorer < UploadsSaver
      def restore
        return true unless File.directory?(uploads_export_path)

        copy_files(uploads_export_path, uploads_path)
      rescue => e
        @shared.error(e)
        false
      end
    end
  end
end
