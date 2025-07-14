# frozen_string_literal: true

module Resolvers
  module WorkItems
    class WidgetsResolver < BaseResolver
      type [::GraphQL::Types::String], null: true

      MAX_TYPES = 100

      argument :ids,
        [::Types::GlobalIDType[::WorkItems::Type]],
        required: true,
        description: <<~DESC.squish
          Global ID array of work items types to fetch available widgets for.
          A max of #{MAX_TYPES} IDs can be provided at a time.
        DESC

      argument :union,
        ::GraphQL::Types::Boolean,
        default_value: false,
        description: <<~DESC.squish
          When true, returns the union of widgets across all work item types.
          When false, returns only widgets common to all work item types.
        DESC

      def ready?(**args)
        if args[:ids].size > MAX_TYPES
          raise Gitlab::Graphql::Errors::ArgumentError,
            format(
              _('No more than %{max_work_items} work items can be loaded at the same time'),
              max_work_items: MAX_TYPES
            )
        end

        super
      end

      def resolve(ids:, union: false)
        all_widgets = ::WorkItems::Type
          .id_in(ids.map(&:model_id))
          .with_widget_definition_preload
          .map { |type| type.widgets(resource_parent).map { |widget| widget.widget_type.upcase } }

        return [] if all_widgets.blank?

        if union
          all_widgets.reduce(:|)
        else
          all_widgets.reduce(:&)
        end
      end

      private

      def resource_parent
        object.respond_to?(:sync) ? object.sync : object
      end
      strong_memoize_attr :resource_parent
    end
  end
end
