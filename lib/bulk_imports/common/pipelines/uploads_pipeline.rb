# frozen_string_literal: true

module BulkImports
  module Common
    module Pipelines
      class UploadsPipeline
        include Pipeline
        include IndexCacheStrategy

        AVATAR_PATTERN = %r{.*\/#{BulkImports::UploadsExportService::AVATAR_PATH}\/(?<identifier>.*)}

        AvatarLoadingError = Class.new(StandardError)

        file_extraction_pipeline!

        def extract(_context)
          download_service.execute
          decompression_service.execute
          extraction_service.execute

          upload_file_paths = Dir.glob(File.join(tmpdir, '**', '*'))

          BulkImports::Pipeline::ExtractedData.new(data: upload_file_paths)
        end

        def load(context, file_path)
          # Validate that the path is OK to load
          Gitlab::PathTraversal.check_allowed_absolute_path_and_path_traversal!(file_path, [Dir.tmpdir])
          return if File.directory?(file_path)
          return if Gitlab::Utils::FileInfo.linked?(file_path)

          avatar_path = AVATAR_PATTERN.match(file_path)
          return save_avatar(file_path) if avatar_path

          dynamic_path = file_uploader.extract_dynamic_path(file_path)
          return unless dynamic_path

          named_captures = dynamic_path.named_captures.symbolize_keys

          UploadService.new(context.portable, File.open(file_path, 'r'), file_uploader, **named_captures).execute
        end

        def after_run(_)
          FileUtils.rm_rf(tmpdir)
        end

        private

        def download_service
          BulkImports::FileDownloadService.new(
            configuration: context.configuration,
            relative_url: context.entity.relation_download_url_path(relation, context.extra[:batch_number]),
            tmpdir: tmpdir,
            filename: targz_filename
          )
        end

        def decompression_service
          BulkImports::FileDecompressionService.new(tmpdir: tmpdir, filename: targz_filename)
        end

        def extraction_service
          BulkImports::ArchiveExtractionService.new(tmpdir: tmpdir, filename: tar_filename)
        end

        def relation
          BulkImports::FileTransfer::BaseConfig::UPLOADS_RELATION
        end

        def tar_filename
          "#{relation}.tar"
        end

        def targz_filename
          "#{tar_filename}.gz"
        end

        def tmpdir
          @tmpdir ||= Dir.mktmpdir('bulk_imports')
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
