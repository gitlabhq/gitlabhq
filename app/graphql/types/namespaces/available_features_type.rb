# frozen_string_literal: true

module Types
  module Namespaces
    class AvailableFeaturesType < BaseObject # rubocop:disable Graphql/AuthorizeTypes -- parent is already authorized
      graphql_name 'NamespaceAvailableFeatures'

      include IssuesHelper

      field :has_blocked_issues_feature,
        GraphQL::Types::Boolean,
        null: false,
        description: 'Whether blocked issues are enabled for the namespace.',
        resolver_method: :blocked_issues_enabled?,
        experiment: { milestone: '18.3' }

      field :has_custom_fields_feature,
        GraphQL::Types::Boolean,
        null: false,
        description: 'Whether custom fields are enabled for the namespace.',
        resolver_method: :custom_fields_enabled?,
        experiment: { milestone: '18.3' }

      field :has_design_management_feature,
        GraphQL::Types::Boolean,
        null: false,
        description: 'Whether design management is enabled for the namespace.',
        resolver_method: :design_management_enabled?,
        experiment: { milestone: '18.6' }

      field :has_epics_feature,
        GraphQL::Types::Boolean,
        null: false,
        description: 'Whether epics are enabled for the namespace.',
        resolver_method: :epics_enabled?,
        experiment: { milestone: '18.1' }

      field :has_group_bulk_edit_feature,
        GraphQL::Types::Boolean,
        null: false,
        description: 'Whether group bulk edit is enabled for the namespace.',
        resolver_method: :group_bulk_edit_enabled?,
        experiment: { milestone: '18.3' }

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

      field :has_work_item_status_feature,
        GraphQL::Types::Boolean,
        null: false,
        description: 'Whether work item statuses are enabled for the namespace.',
        resolver_method: :work_item_status_enabled?,
        experiment: { milestone: '18.3' }

      field :has_work_item_planning_view_feature,
        GraphQL::Types::Boolean,
        null: false,
        description: 'Whether work item planning view is enabled for the namespace.',
        resolver_method: :work_item_planning_view_enabled?,
        experiment: { milestone: '18.6' }

      field :has_duo_remote_flows_feature,
        GraphQL::Types::Boolean,
        null: false,
        description: 'Whether Duo remote flows are enabled for the namespace.',
        resolver_method: :has_duo_remote_flows_feature_enabled?,
        experiment: { milestone: '18.6' }

      def blocked_issues_enabled?
        object.licensed_feature_available?(:blocked_issues)
      end

      def custom_fields_enabled?
        object.licensed_feature_available?(:custom_fields)
      end

      def design_management_enabled?
        return false unless object.project_namespace?

        object.project.design_management_enabled?
      end

      def epics_enabled?
        object.licensed_feature_available?(:epics)
      end

      def group_bulk_edit_enabled?
        object.licensed_feature_available?(:group_bulk_edit)
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

      def work_item_status_enabled?
        object.licensed_feature_available?(:work_item_status)
      end

      def work_item_planning_view_enabled?
        case object
        when Group, ::Namespaces::ProjectNamespace
          object.owner_entity.work_items_consolidated_list_enabled?(current_user)
        when ::Namespaces::UserNamespace
          return true if Feature.enabled?(:work_item_planning_view, type: :wip) # rubocop:disable Gitlab/FeatureFlagWithoutActor -- the flag is for group

          current_user.present? && Feature.enabled?(:work_items_consolidated_list_user, current_user)
        else
          # rubocop:disable Gitlab/NoCodeCoverageComment -- defensive fallback for unknown namespace types; unreachable due to GraphQL type system guarantees
          # :nocov:
          false
          # :nocov:
          # rubocop:enable Gitlab/NoCodeCoverageComment
        end
      end

      def has_duo_remote_flows_feature_enabled?
        object.owner_entity.try(:duo_remote_flows_enabled) || false
      end
    end
  end
end
