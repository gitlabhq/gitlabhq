# frozen_string_literal: true

module Resolvers
  module WorkItems
    class UserWorkItemsResolver < BaseResolver
      prepend ::WorkItems::LookAheadPreloads
      include SearchArguments
      include ::WorkItems::SharedFilterArguments

      NON_FILTER_ARGUMENTS = %i[sort lookahead].freeze

      argument :sort,
        ::Types::WorkItems::SortEnum,
        description: 'Sort work items by criteria.',
        required: false,
        default_value: :created_desc

      type Types::WorkItemType.connection_type, null: true

      before_connection_authorization do |nodes, current_user|
        ::Preloaders::IssuablesPreloader.new(nodes, current_user, [:namespace]).preload_all
      end

      def ready?(**args)
        unless filter_provided?(args)
          raise Gitlab::Graphql::Errors::ArgumentError,
            _('You must provide at least one filter argument for this query')
        end

        super
      end

      def resolve_with_lookahead(**args)
        apply_lookahead(::WorkItems::WorkItemsFinder.new(current_user, prepare_finder_params(args)).execute)
      end

      private

      def filter_provided?(args)
        args.except(*NON_FILTER_ARGUMENTS).values.any?(&:present?)
      end
    end
  end
end

Resolvers::WorkItems::UserWorkItemsResolver.prepend_mod
