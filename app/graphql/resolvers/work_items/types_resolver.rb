# frozen_string_literal: true

module Resolvers
  module WorkItems
    class TypesResolver < BaseResolver
      type Types::WorkItems::TypeType.connection_type, null: true

      def resolve
        return unless Feature.enabled?(:work_items, object)

        # This will require a finder in the future when groups/projects get their work item types
        # All groups/projects use the default types for now
        ::WorkItems::Type.default.order_by_name_asc
      end
    end
  end
end
