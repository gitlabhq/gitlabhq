# frozen_string_literal: true

module BulkImports
  module Common
    module Pipelines
      class UploadsPipeline
        include Pipeline
        include Gitlab::ImportExport::CommandLineUtil

        FILENAME = 'uploads.tar.gz'
        AVATAR_PATTERN = %r{.*\/#{BulkImports::UploadsExportService::AVATAR_PATH}\/(?<identifier>.*)}.freeze

        AvatarLoadingError = Class.new(StandardError)

        def extract(context)
          download_service(tmp_dir, context).execute
          untar_zxf(archive: File.join(tmp_dir, FILENAME), dir: tmp_dir)
          upload_file_paths = Dir.glob(File.join(tmp_dir, '**', '*'))

          BulkImports::Pipeline::ExtractedData.new(data: upload_file_paths)
        end

        def load(context, file_path)
          avatar_path = AVATAR_PATTERN.match(file_path)

          return save_avatar(file_path) if avatar_path

          dynamic_path = file_uploader.extract_dynamic_path(file_path)

          return unless dynamic_path
          return if File.directory?(file_path)

          named_captures = dynamic_path.named_captures.symbolize_keys

          UploadService.new(context.portable, File.open(file_path, 'r'), file_uploader, **named_captures).execute
        end

        def after_run(_)
          FileUtils.remove_entry(tmp_dir)
        end

        private

        def download_service(tmp_dir, context)
          BulkImports::FileDownloadService.new(
            configuration: context.configuration,
            relative_url: context.entity.relation_download_url_path('uploads'),
            dir: tmp_dir,
            filename: FILENAME
          )
        end

        def tmp_dir
          @tmp_dir ||= Dir.mktmpdir('bulk_imports')
        end

        def file_uploader
          @file_uploader ||= if context.entity.group?
                               NamespaceFileUploader
                             else
                               FileUploader
                             end
        end

        def save_avatar(file_path)
          File.open(file_path) do |avatar|
            service = context.entity.update_service.new(portable, current_user, avatar: avatar)

            unless service.execute
              raise AvatarLoadingError, portable.errors.full_messages.to_sentence
            end
          end
        end
      end
    end
  end
end
