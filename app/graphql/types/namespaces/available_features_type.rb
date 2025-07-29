# frozen_string_literal: true

module Types
  module Namespaces
    class AvailableFeaturesType < BaseObject # rubocop:disable Graphql/AuthorizeTypes -- parent is already authorized
      graphql_name 'NamespaceAvailableFeatures'

      include IssuesHelper

      field :has_epics_feature,
        GraphQL::Types::Boolean,
        null: false,
        description: 'Whether epics are enabled for the namespace.',
        resolver_method: :epics_enabled?,
        experiment: { milestone: '18.1' }

      field :has_issuable_health_status_feature,
        GraphQL::Types::Boolean,
        null: false,
        description: 'Whether issuable health status is enabled for the namespace.',
        resolver_method: :issuable_health_status_enabled?,
        experiment: { milestone: '18.1' }

      field :has_issue_date_filter_feature,
        GraphQL::Types::Boolean,
        null: false,
        description: 'Whether issue date filter is enabled for the namespace.',
        resolver_method: :issue_date_filter_enabled?,
        experiment: { milestone: '18.1' }

      field :has_issue_weights_feature,
        GraphQL::Types::Boolean,
        null: false,
        description: 'Whether issue weights are enabled for the namespace.',
        resolver_method: :issue_weights_enabled?,
        experiment: { milestone: '18.1' }

      field :has_iterations_feature,
        GraphQL::Types::Boolean,
        null: false,
        description: 'Whether iterations are enabled for the namespace.',
        resolver_method: :iterations_enabled?,
        experiment: { milestone: '18.1' }

      field :has_linked_items_epics_feature,
        GraphQL::Types::Boolean,
        null: false,
        description: 'Whether linked items epics are enabled for the namespace.',
        resolver_method: :linked_items_epics_enabled?,
        experiment: { milestone: '18.1' }

      field :has_okrs_feature,
        GraphQL::Types::Boolean,
        null: false,
        description: 'Whether OKRs are enabled for the namespace.',
        resolver_method: :okrs_enabled?,
        experiment: { milestone: '18.1' }

      field :has_quality_management_feature,
        GraphQL::Types::Boolean,
        null: false,
        description: 'Whether quality management is enabled for the namespace.',
        resolver_method: :quality_management_enabled?,
        experiment: { milestone: '18.1' }

      field :has_scoped_labels_feature,
        GraphQL::Types::Boolean,
        null: false,
        description: 'Whether scoped labels are enabled for the namespace.',
        resolver_method: :scoped_labels_enabled?,
        experiment: { milestone: '18.1' }

      field :has_subepics_feature,
        GraphQL::Types::Boolean,
        null: false,
        description: 'Whether subepics are enabled for the namespace.',
        resolver_method: :subepics_enabled?,
        experiment: { milestone: '18.1' }

      def epics_enabled?
        object.licensed_feature_available?(:epics)
      end

      def issuable_health_status_enabled?
        object.licensed_feature_available?(:issuable_health_status)
      end

      def issue_date_filter_enabled?
        has_issue_date_filter_feature?(object, current_user)
      end

      def issue_weights_enabled?
        object.licensed_feature_available?(:issue_weights)
      end

      def iterations_enabled?
        object.licensed_feature_available?(:iterations)
      end

      def linked_items_epics_enabled?
        object.licensed_feature_available?(:linked_items_epics)
      end

      def okrs_enabled?
        object.licensed_feature_available?(:okrs)
      end

      def quality_management_enabled?
        object.licensed_feature_available?(:quality_management)
      end

      def scoped_labels_enabled?
        object.licensed_feature_available?(:scoped_labels)
      end

      def subepics_enabled?
        object.licensed_feature_available?(:subepics)
      end
    end
  end
end
