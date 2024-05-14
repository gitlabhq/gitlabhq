# frozen_string_literal: true

module Types
  # rubocop: disable Graphql/AuthorizeTypes
  # Only used to render the current user's own preferences
  class UserPreferencesType < BaseObject
    graphql_name 'UserPreferences'

    field :extensions_marketplace_opt_in_status, Types::ExtensionsMarketplaceOptInStatusEnum,
      description: 'Status of the Web IDE Extension Marketplace opt-in for the user.',
      null: false

    field :issues_sort, Types::IssueSortEnum,
      description: 'Sort order for issue lists.',
      null: true

    field :visibility_pipeline_id_type, Types::VisibilityPipelineIdTypeEnum,
      description: 'Determines whether the pipeline list shows ID or IID.',
      null: true

    field :use_web_ide_extension_marketplace, GraphQL::Types::Boolean,
      description: 'Whether Web IDE Extension Marketplace is enabled for the user.',
      null: false,
      deprecated: { reason: 'Use `extensions_marketplace_opt_in_status` instead', milestone: '16.11' }

    def issues_sort
      object.issues_sort.to_sym
    end
  end
end
