# frozen_string_literal: true

module BulkImports
  module Projects
    module Pipelines
      class ProjectAttributesPipeline
        include Pipeline

        transformer ::BulkImports::Common::Transformers::ProhibitedAttributesTransformer

        def extract(context)
          download_service(tmp_dir, context).execute
          decompression_service(tmp_dir).execute
          project_attributes = json_decode(json_attributes)

          BulkImports::Pipeline::ExtractedData.new(data: project_attributes)
        end

        def transform(_, data)
          subrelations = config.portable_relations_tree.keys.map(&:to_s)

          Gitlab::ImportExport::AttributeCleaner.clean(
            relation_hash: data,
            relation_class: Project,
            excluded_keys: config.relation_excluded_keys(:project)
          ).except(*subrelations)
        end

        def load(_, data)
          portable.assign_attributes(data)
          portable.reconcile_shared_runners_setting!
          portable.drop_visibility_level!
          portable.save!
        end

        def after_run(_)
          FileUtils.remove_entry(tmp_dir)
        end

        def json_attributes
          @json_attributes ||= File.read(File.join(tmp_dir, filename))
        end

        private

        def tmp_dir
          @tmp_dir ||= Dir.mktmpdir
        end

        def config
          @config ||= BulkImports::FileTransfer.config_for(portable)
        end

        def download_service(tmp_dir, context)
          @download_service ||= BulkImports::FileDownloadService.new(
            configuration: context.configuration,
            relative_url: context.entity.relation_download_url_path(BulkImports::FileTransfer::BaseConfig::SELF_RELATION),
            dir: tmp_dir,
            filename: compressed_filename
          )
        end

        def decompression_service(tmp_dir)
          @decompression_service ||= BulkImports::FileDecompressionService.new(dir: tmp_dir, filename: compressed_filename)
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
