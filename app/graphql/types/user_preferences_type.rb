# frozen_string_literal: true

module Types
  class UserPreferencesType < BaseObject
    graphql_name 'UserPreferences'

    authorize :read_user_preference

    alias_method :user_preference, :object

    field :extensions_marketplace_opt_in_status, Types::ExtensionsMarketplaceOptInStatusEnum,
      description: 'Status of the Web IDE Extension Marketplace opt-in for the user.',
      null: false

    field :issues_sort, Types::IssueSortEnum,
      description: 'Sort order for issue lists.',
      null: true

    field :visibility_pipeline_id_type, Types::VisibilityPipelineIdTypeEnum,
      description: 'Determines whether the pipeline list shows ID or IID.',
      null: true

    # rubocop:disable GraphQL/ExtractType -- These are stored as user preferences
    field :use_work_items_view, GraphQL::Types::Boolean,
      description: 'Use work item view instead of legacy issue view.',
      null: true

    field :merge_request_dashboard_list_type, Types::MergeRequests::DashboardListTypeEnum,
      description: 'Merge request dashboard list rendering type.',
      null: true

    field :projects_sort,
      Types::Projects::ProjectSortEnum,
      description: 'Sort order for projects.',
      null: true

    field :organization_groups_projects_sort,
      Types::Organizations::GroupsProjectsSortEnum,
      description: 'Sort order for organization groups and projects.',
      null: true,
      experiment: { milestone: '17.2' }

    field :organization_groups_projects_display,
      Types::Organizations::GroupsProjectsDisplayEnum,
      null: false,
      description: 'Default list view for organization groups and projects.',
      experiment: { milestone: '17.2' }
    # rubocop:enable GraphQL/ExtractType

    field :timezone,
      GraphQL::Types::String,
      null: true,
      description: 'Timezone of the user.',
      experiment: { milestone: '17.7' }

    field :work_items_display_settings,
      type: GraphQL::Types::JSON,
      null: false,
      description: 'Display settings for the work item lists.'

    def issues_sort
      user_preference.issues_sort&.to_sym
    end

    def projects_sort
      user_preference.projects_sort&.to_sym
    end

    def organization_groups_projects_sort
      user_preference.organization_groups_projects_sort&.to_sym
    end

    def extensions_marketplace_opt_in_status
      user = user_preference.user

      ::WebIde::ExtensionMarketplaceOptIn.opt_in_status(
        user: user,
        marketplace_home_url: ::WebIde::ExtensionMarketplace.marketplace_home_url(user: user)
      )
    end
  end
end
