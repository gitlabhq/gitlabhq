# frozen_string_literal: true

module Gitlab
  module ImportExport
    class UploadsManager
      include Gitlab::ImportExport::CommandLineUtil

      UPLOADS_BATCH_SIZE = 100

      def initialize(project:, shared:, relative_export_path: 'uploads')
        @project = project
        @shared = shared
        @relative_export_path = relative_export_path
      end

      def save
        copy_project_uploads

        true
      rescue StandardError => e
        @shared.error(e)
        false
      end

      def restore
        Dir["#{uploads_export_path}/**/*"].each do |upload|
          next if File.directory?(upload)

          add_upload(upload)
        end

        true
      rescue StandardError => e
        @shared.error(e)
        false
      end

      private

      def add_upload(upload)
        uploader_context = FileUploader.extract_dynamic_path(upload).named_captures.symbolize_keys

        UploadService.new(@project, File.open(upload, 'r'), FileUploader, **uploader_context).execute.to_h
      end

      def copy_project_uploads
        each_uploader do |uploader|
          next unless uploader.file

          if uploader.upload.local?
            next unless uploader.upload.exist?

            copy_files(uploader.absolute_path, File.join(uploads_export_path, uploader.upload.path))
          else
            download_and_copy(uploader)
          end
        end
      end

      def uploads_export_path
        @uploads_export_path ||= File.join(@shared.export_path, @relative_export_path)
      end

      def each_uploader
        avatar_path = @project.avatar&.upload&.path

        if @relative_export_path == 'avatar'
          yield(@project.avatar)
        else
          project_uploads_except_avatar(avatar_path).find_each(batch_size: UPLOADS_BATCH_SIZE) do |upload|
            yield(upload.retrieve_uploader)
          end
        end
      end

      def project_uploads_except_avatar(avatar_path)
        return @project.uploads unless avatar_path

        @project.uploads.where.not(path: avatar_path)
      end

      def download_and_copy(upload)
        secret = upload.try(:secret) || ''
        upload_path = File.join(uploads_export_path, secret, upload.filename)

        mkdir_p(File.join(uploads_export_path, secret))

        download_or_copy_upload(upload, upload_path)
      rescue Errno::ENAMETOOLONG => e
        # Do not fail entire project export if downloaded file has filename that exceeds 255 characters.
        # Ignore raised exception, skip such upload, log the error and keep going with the export instead.
        Gitlab::ErrorTracking.log_exception(e, project_id: @project.id)
      end
    end
  end
end
