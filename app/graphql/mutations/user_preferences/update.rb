# frozen_string_literal: true

module Mutations
  module UserPreferences
    class Update < BaseMutation
      graphql_name 'UserPreferencesUpdate'

      NON_NULLABLE_ARGS = [
        :extensions_marketplace_opt_in_status,
        :organization_groups_projects_display,
        :visibility_pipeline_id_type,
        :use_work_items_view
      ].freeze

      argument :extensions_marketplace_opt_in_status, Types::ExtensionsMarketplaceOptInStatusEnum,
        required: false,
        description: 'Status of the Web IDE Extension Marketplace opt-in for the user.'
      argument :issues_sort, Types::IssueSortEnum,
        required: false,
        description: 'Sort order for issue lists.'
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

      field :user_preferences,
        Types::UserPreferencesType,
        null: true,
        description: 'User preferences after mutation.'

      def resolve(**attributes)
        attributes.delete_if { |key, value| NON_NULLABLE_ARGS.include?(key) && value.nil? }
        user_preferences = current_user.user_preference
        user_preferences.update(attributes)

        {
          user_preferences: user_preferences.valid? ? user_preferences : nil,
          errors: errors_on_object(user_preferences)
        }
      end
    end
  end
end
