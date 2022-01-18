# frozen_string_literal: true

module BulkImports
  module Projects
    module Pipelines
      class ProjectAttributesPipeline
        include Pipeline

        transformer ::BulkImports::Common::Transformers::ProhibitedAttributesTransformer

        def extract(_context)
          download_service.execute
          decompression_service.execute

          project_attributes = json_decode(json_attributes)

          BulkImports::Pipeline::ExtractedData.new(data: project_attributes)
        end

        def transform(_context, data)
          subrelations = config.portable_relations_tree.keys.map(&:to_s)

          Gitlab::ImportExport::AttributeCleaner.clean(
            relation_hash: data,
            relation_class: Project,
            excluded_keys: config.relation_excluded_keys(:project)
          ).except(*subrelations)
        end

        def load(_context, data)
          portable.assign_attributes(data)
          portable.reconcile_shared_runners_setting!
          portable.drop_visibility_level!
          portable.save!
        end

        def after_run(_context)
          FileUtils.remove_entry(tmpdir) if Dir.exist?(tmpdir)
        end

        def json_attributes
          @json_attributes ||= File.read(File.join(tmpdir, filename))
        end

        private

        def tmpdir
          @tmpdir ||= Dir.mktmpdir('bulk_imports')
        end

        def config
          @config ||= BulkImports::FileTransfer.config_for(portable)
        end

        def download_service
          @download_service ||= BulkImports::FileDownloadService.new(
            configuration: context.configuration,
            relative_url:  context.entity.relation_download_url_path(BulkImports::FileTransfer::BaseConfig::SELF_RELATION),
            tmpdir: tmpdir,
            filename: compressed_filename
          )
        end

        def decompression_service
          @decompression_service ||= BulkImports::FileDecompressionService.new(tmpdir: tmpdir, filename: compressed_filename)
        end

        def compressed_filename
          "#{filename}.gz"
        end

        def filename
          "#{BulkImports::FileTransfer::BaseConfig::SELF_RELATION}.json"
        end

        def json_decode(string)
          Gitlab::Json.parse(string)
        rescue JSON::ParserError => e
          Gitlab::ErrorTracking.log_exception(e)

          raise BulkImports::Error, 'Incorrect JSON format'
        end
      end
    end
  end
end
