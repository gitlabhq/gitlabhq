# frozen_string_literal: true

module Types
  # rubocop:disable Graphql/AuthorizeTypes -- This is not necessary because the superclass declares the authorization
  class CurrentUserType < ::Types::UserType
    graphql_name 'CurrentUser'
    description 'The currently authenticated GitLab user.'

    field :assignee_or_reviewer_merge_requests,
      resolver: Resolvers::MergeRequests::AssigneeOrReviewerMergeRequestsResolver,
      description: 'Merge requests the current user is an assignee or a reviewer of.'

    field :recently_viewed_issues,
      resolver: Resolvers::Users::RecentlyViewedIssuesResolver,
      description: 'Most-recently viewed issues for the current user.',
      experiment: { milestone: '17.9' }

    field :recently_viewed_merge_requests,
      resolver: Resolvers::Users::RecentlyViewedMergeRequestsResolver,
      description: 'Most-recently viewed merge requests for the current user.',
      experiment: { milestone: '17.10' }

    field :recently_viewed_items, # rubocop:disable GraphQL/ExtractType -- This is the extract type
      [Types::Users::RecentlyViewedItemType],
      null: true,
      description: 'Most-recently viewed items for the current user.',
      resolver: Resolvers::Users::RecentlyViewedItemsResolver

    field :work_items,
      null: true,
      resolver: Resolvers::WorkItems::UserWorkItemsResolver,
      description: 'Find work items visible to the current user.',
      experiment: { milestone: '17.10' }

    field :work_item_preferences, # rubocop:disable GraphQL/ExtractType -- fields with different contexts
      resolver: ::Resolvers::WorkItems::UserPreferenceResolver,
      null: true,
      experiment: { milestone: '17.10' },
      description: 'User preferences for the given work item type and namespace.'

    field :runners,
      Types::Ci::RunnerType.connection_type,
      null: true,
      resolver: Resolvers::Ci::UserRunnersResolver,
      experiment: { milestone: '18.3' },
      description: 'List all runners the current user manages.'
  end
  # rubocop:enable Graphql/AuthorizeTypes
end

::Types::CurrentUserType.prepend_mod
