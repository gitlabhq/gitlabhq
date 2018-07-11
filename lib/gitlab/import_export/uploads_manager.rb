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

      def save
        copy_files(@from, uploads_export_path) if File.directory?(@from)

        if File.file?(@from) && @relative_export_path == 'avatar'
          copy_files(@from, File.join(uploads_export_path, @project.avatar.filename))
        end

        copy_from_object_storage

        true
      rescue => e
        @shared.error(e)
        false
      end

      def restore
        Dir["#{uploads_export_path}/**/*"].each do |upload|
          next if File.directory?(upload)

          add_upload(upload)
        end

        true
      rescue => e
        @shared.error(e)
        false
      end

      private

      def add_upload(upload)
        secret, identifier = upload.split('/').last(2)

        uploader_context = {
          secret: secret,
          identifier: identifier
        }

        UploadService.new(@project, File.open(upload, 'r'), FileUploader, uploader_context).execute
      end

      def copy_from_object_storage
        return unless Gitlab::ImportExport.object_storage?

        uploads.each do |upload_model|
          next unless upload_model.file
          next if upload_model.upload.local? # Already copied, using  the old  method

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
        secret = upload.try(:secret) || ''
        upload_path = File.join(uploads_export_path, secret, upload.filename)

        mkdir_p(File.join(uploads_export_path, secret))

        File.open(upload_path, 'w') do |file|
          IO.copy_stream(URI.parse(upload.file.url).open, file)
        end
      end
    end
  end
end
