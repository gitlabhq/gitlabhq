# frozen_string_literal: true

module BulkImports
  module Common
    module Pipelines
      class UploadsPipeline
        include Pipeline
        include Gitlab::ImportExport::CommandLineUtil

        FILENAME = 'uploads.tar.gz'

        def extract(context)
          download_service(tmp_dir, context).execute
          untar_zxf(archive: File.join(tmp_dir, FILENAME), dir: tmp_dir)
          upload_file_paths = Dir.glob(File.join(tmp_dir, '**', '*'))

          BulkImports::Pipeline::ExtractedData.new(data: upload_file_paths)
        end

        def load(context, file_path)
          dynamic_path = FileUploader.extract_dynamic_path(file_path)

          return unless dynamic_path
          return if File.directory?(file_path)

          named_captures = dynamic_path.named_captures.symbolize_keys

          UploadService.new(context.portable, File.open(file_path, 'r'), FileUploader, **named_captures).execute
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
      end
    end
  end
end
