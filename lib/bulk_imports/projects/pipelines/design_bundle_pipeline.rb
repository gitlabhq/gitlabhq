# frozen_string_literal: true

module BulkImports
  module Projects
    module Pipelines
      class DesignBundlePipeline
        include Pipeline
        include IndexCacheStrategy

        file_extraction_pipeline!
        relation_name BulkImports::FileTransfer::ProjectConfig::DESIGN_BUNDLE_RELATION

        def extract(_context)
          download_service.execute
          decompression_service.execute
          extraction_service.execute

          bundle_path = File.join(tmpdir, "#{self.class.relation}.bundle")

          BulkImports::Pipeline::ExtractedData.new(data: bundle_path)
        end

        def load(_context, bundle_path)
          Gitlab::PathTraversal.check_path_traversal!(bundle_path)
          Gitlab::PathTraversal.check_allowed_absolute_path!(bundle_path, [Dir.tmpdir])

          return unless portable.lfs_enabled?
          return unless File.exist?(bundle_path)
          return if File.directory?(bundle_path)
          return if Gitlab::Utils::FileInfo.linked?(bundle_path)

          portable.design_repository.create_from_bundle(bundle_path)
        end

        def after_run(_)
          FileUtils.rm_rf(tmpdir)
        end

        private

        def download_service
          BulkImports::FileDownloadService.new(
            configuration: context.configuration,
            relative_url: context.entity.relation_download_url_path(self.class.relation),
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

        def tar_filename
          "#{self.class.relation}.tar"
        end

        def targz_filename
          "#{tar_filename}.gz"
        end

        def tmpdir
          @tmpdir ||= Dir.mktmpdir('bulk_imports')
        end
      end
    end
  end
end
