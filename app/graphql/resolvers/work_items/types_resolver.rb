# frozen_string_literal: true

module Resolvers
  module WorkItems
    class TypesResolver < BaseResolver
      type Types::WorkItems::TypeType.connection_type, null: true

      argument :taskable, ::GraphQL::Types::Boolean,
               required: false,
               description: 'If `true`, only taskable work item types will be returned.' \
                            ' Argument is experimental and can be removed in the future without notice.'

      def resolve(taskable: nil)
        return unless feature_flag_enabled_for_parent?(object)

        # This will require a finder in the future when groups/projects get their work item types
        # All groups/projects use the default types for now
        base_scope = ::WorkItems::Type.default
        base_scope = base_scope.by_type(:task) if taskable

        base_scope.order_by_name_asc
      end

      private

      def feature_flag_enabled_for_parent?(parent)
        return false unless parent.is_a?(::Project) || parent.is_a?(::Group)

        parent.work_items_feature_flag_enabled?
      end
    end
  end
end
