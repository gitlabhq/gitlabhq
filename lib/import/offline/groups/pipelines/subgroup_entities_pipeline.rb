# frozen_string_literal: true

module Import
  module Offline
    module Groups
      module Pipelines
        class SubgroupEntitiesPipeline
          include ::BulkImports::Pipeline
          include ::BulkImports::Pipeline::HexdigestCacheStrategy

          transformer ::BulkImports::Common::Transformers::ProhibitedAttributesTransformer
          transformer ::BulkImports::Groups::Transformers::SubgroupToEntityTransformer

          def extract(context)
            configuration = context.offline_configuration

            subgroups = configuration.subgroup_paths_for(context.entity.source_full_path)

            ::BulkImports::Pipeline::ExtractedData.new(data: subgroups)
          end

          def load(context, data)
            context.bulk_import.entities.create!(data)
          end
        end
      end
    end
  end
end
