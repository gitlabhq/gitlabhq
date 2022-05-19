# frozen_string_literal: true

module BulkImports
  module Groups
    module Pipelines
      class GroupAttributesPipeline
        include Pipeline

        file_extraction_pipeline!

        relation_name BulkImports::FileTransfer::BaseConfig::SELF_RELATION

        extractor ::BulkImports::Common::Extractors::JsonExtractor, relation: relation

        transformer ::BulkImports::Common::Transformers::ProhibitedAttributesTransformer

        def transform(_context, data)
          return unless data

          data.symbolize_keys.slice(:membership_lock)
        end

        def load(_context, data)
          return unless data

          ::Groups::UpdateService.new(portable, current_user, data).execute
        end

        def after_run(_context)
          extractor.remove_tmpdir
        end
      end
    end
  end
end
