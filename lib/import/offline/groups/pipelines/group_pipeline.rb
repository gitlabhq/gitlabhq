# frozen_string_literal: true

module Import
  module Offline
    module Groups
      module Pipelines
        class GroupPipeline
          include ::BulkImports::Pipeline
          include ::BulkImports::Pipeline::HexdigestCacheStrategy

          file_extraction_pipeline!
          abort_on_failure!

          relation_name ::BulkImports::FileTransfer::BaseConfig::SELF_RELATION

          extractor ::BulkImports::Common::Extractors::JsonExtractor, relation: relation

          transformer ::BulkImports::Common::Transformers::ProhibitedAttributesTransformer
          transformer Import::Offline::Groups::Transformers::GroupAttributesTransformer

          loader ::BulkImports::Groups::Loaders::GroupLoader

          def after_run(_context)
            extractor.remove_tmpdir
          end
        end
      end
    end
  end
end
