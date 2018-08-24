module Gitlab
  module ImportExport
    class UploadsSaver
      include Gitlab::ImportExport::CommandLineUtil

      UPLOADS_BATCH_SIZE = 100

      def initialize(project:, shared:)
        @project = project
        @shared = shared
      end

      def save
        copy_project_uploads
        true
      rescue => e
        @shared.error(e)
        false
      end

      def copy_project_uploads
        each_uploader do |uploader|
          next unless uploader.file
          # export of object stored uploads is not yet implemented
          next unless uploader.upload.local?
          next unless uploader.upload.exist?

          copy_files(uploader.absolute_path, File.join(uploads_export_path, uploader.upload.path))
        end
      end

      def each_uploader
        @project.uploads.find_each(batch_size: UPLOADS_BATCH_SIZE) do |upload|
          yield(upload.build_uploader)
        end
      end

      def uploads_path
        FileUploader.absolute_base_dir(@project)
      end

      def uploads_export_path
        File.join(@shared.export_path, 'uploads')
      end
    end
  end
end
