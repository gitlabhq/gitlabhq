module Gitlab
  module ImportExport
    class UploadsManager
      include Gitlab::ImportExport::CommandLineUtil

      def initialize(project:, shared:, relative_export_path: 'uploads', from: nil)
        @project = project
        @shared = shared
        @relative_export_path = relative_export_path
        @from = from || default_uploads_path
      end

      def copy
        copy_files(@from, uploads_export_path) if File.directory?(@from)

        copy_from_object_storage
      end

      private

      def copy_from_object_storage
        return unless Gitlab::ImportExport.object_storage?
        return if uploads.empty?

        mkdir_p(uploads_export_path)

        uploads.each do |upload_model|
          next unless upload_model.file
          next if upload_model.upload.local? # Already copied

          download_and_copy(upload_model)
        end
      end

      def default_uploads_path
        FileUploader.absolute_base_dir(@project)
      end

      def uploads_export_path
        @uploads_export_path ||= File.join(@shared.export_path, @relative_export_path)
      end

      def uploads
        @uploads ||= begin
          if @relative_export_path == 'avatar'
            [@project.avatar].compact
          else
            (@project.uploads - [@project.avatar&.upload]).map(&:build_uploader)
          end
        end
      end

      def download_and_copy(upload)
        upload_path = File.join(uploads_export_path, upload.filename)

        File.open(upload_path, 'w') do |file|
          IO.copy_stream(URI.parse(upload.file.url).open, file)
        end
      end
    end
  end
end
