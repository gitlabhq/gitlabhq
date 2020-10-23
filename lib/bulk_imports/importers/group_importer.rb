# frozen_string_literal: true

# Imports a top level group into a destination
# Optionally imports into parent group
# Entity must be of type: 'group' & have parent_id: nil
# Subgroups not handled yet
module BulkImports
  module Importers
    class GroupImporter
      def initialize(entity_id)
        @entity_id = entity_id
      end

      def execute
        return if entity.parent

        bulk_import = entity.bulk_import
        configuration = bulk_import.configuration

        context = BulkImports::Pipeline::Context.new(
          current_user: bulk_import.user,
          entities: [entity],
          configuration: configuration
        )

        BulkImports::Groups::Pipelines::GroupPipeline.new.run(context)
      end

      def entity
        @entity ||= BulkImports::Entity.find(@entity_id)
      end
    end
  end
end
