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

          true
        else
          true # Proceed without uploads
        end
      rescue => e
        @shared.error(e)
        false
      end

      def uploads_path
        FileUploader.absolute_base_dir(@project)
      end

      def uploads_export_path
        @uploads_export_path ||= File.join(@shared.export_path, 'uploads')
      end
    end
  end
end
