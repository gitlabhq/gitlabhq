# frozen_string_literal: true

module Mutations
  module UserPreferences
    class Update < BaseMutation
      graphql_name 'UserPreferencesUpdate'

      NON_NULLABLE_ARGS = [
        :extensions_marketplace_opt_in_status,
        :organization_groups_projects_display,
        :visibility_pipeline_id_type,
        :use_work_items_view,
        :merge_request_dashboard_list_type
      ].freeze

      argument :extensions_marketplace_opt_in_status, Types::ExtensionsMarketplaceOptInStatusEnum,
        required: false,
        description: 'Status of the Web IDE Extension Marketplace opt-in for the user.'
      argument :issues_sort, Types::IssueSortEnum,
        required: false,
        description: 'Sort order for issue lists.'
      argument :merge_request_dashboard_list_type, Types::MergeRequests::DashboardListTypeEnum,
        required: false,
        description: 'Merge request dashboard list rendering type.'
      argument :merge_requests_sort, Types::MergeRequestSortEnum,
        required: false,
        description: 'Sort order for issue lists.'
      argument :use_work_items_view, GraphQL::Types::Boolean,
        required: false,
        description: 'Use work item view instead of legacy issue view.'
      argument :visibility_pipeline_id_type, Types::VisibilityPipelineIdTypeEnum,
        required: false,
        description: 'Determines whether the pipeline list shows ID or IID.'

      argument :projects_sort, Types::Projects::ProjectSortEnum,
        required: false,
        description: 'Sort order for projects.'

      argument :organization_groups_projects_sort, Types::Organizations::GroupsProjectsSortEnum,
        required: false,
        description: 'Sort order for organization groups and projects.',
        experiment: { milestone: '17.2' }

      argument :organization_groups_projects_display, Types::Organizations::GroupsProjectsDisplayEnum,
        required: false,
        description: 'Default list view for organization groups and projects.',
        experiment: { milestone: '17.2' }

      argument :work_items_display_settings,
        type: GraphQL::Types::JSON,
        description: 'Display settings for the work item lists, e.g.: "{ shouldOpenItemsInSidePanel: false }".',
        required: false,
        experiment: { milestone: '18.1' }

      field :user_preferences,
        Types::UserPreferencesType,
        null: true,
        description: 'User preferences after mutation.'

      def resolve(**attributes)
        attributes.delete_if { |key, value| NON_NULLABLE_ARGS.include?(key) && value.nil? }

        if attributes.include?(:extensions_marketplace_opt_in_status)
          attributes[:extensions_marketplace_opt_in_url] =
            ::WebIde::ExtensionMarketplace.marketplace_home_url(user: current_user)
        end

        user_preferences = current_user.user_preference
        if attributes[:work_items_display_settings].present?
          existing_settings = user_preferences.work_items_display_settings
          attributes[:work_items_display_settings] =
            existing_settings.merge(attributes[:work_items_display_settings])
        end

        user_preferences.update(attributes)

        {
          user_preferences: user_preferences.valid? ? user_preferences : nil,
          errors: errors_on_object(user_preferences)
        }
      end
    end
  end
end
