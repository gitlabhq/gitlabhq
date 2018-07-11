module Gitlab
  module ImportExport
    class UploadsRestorer < UploadsSaver
      def restore
        if Gitlab::ImportExport.object_storage?
          Gitlab::ImportExport::UploadsManager.new(
            project: @project,
            shared: @shared
          ).restore
        elsif File.directory?(uploads_export_path)
          copy_files(uploads_export_path, uploads_path)
        else
          true
        end
      rescue => e
        @shared.error(e)
        false
      end

      def uploads_path
        FileUploader.absolute_base_dir(@project)
      end
    end
  end
end
