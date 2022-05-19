# frozen_string_literal: true

module BulkImports
  module Groups
    module Pipelines
      class NamespaceSettingsPipeline
        include Pipeline

        file_extraction_pipeline!

        relation_name 'namespace_settings'

        extractor ::BulkImports::Common::Extractors::NdjsonExtractor, relation: relation

        transformer ::BulkImports::Common::Transformers::ProhibitedAttributesTransformer

        def transform(_context, data)
          return unless data

          data.first.symbolize_keys.slice(*allowed_attributes)
        end

        def load(_context, data)
          return unless data

          ::Groups::UpdateService.new(portable, current_user, data).execute
        end

        def after_run(_context)
          extractor.remove_tmpdir
        end

        private

        def allowed_attributes
          Gitlab::ImportExport::Config.new(
            config: Gitlab::ImportExport.group_config_file
          ).to_h.dig(:included_attributes, :namespace_settings)
        end
      end
    end
  end
end
