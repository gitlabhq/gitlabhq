# frozen_string_literal: true

module Types
  # rubocop:disable Graphql/AuthorizeTypes -- This is not necessary because the superclass declares the authorization
  class CurrentUserType < ::Types::UserType
    graphql_name 'CurrentUser'
    description 'The currently authenticated GitLab user.'

    field :assignee_or_reviewer_merge_requests,
      resolver: Resolvers::MergeRequests::AssigneeOrReviewerMergeRequestsResolver,
      description: 'Merge requests the current user is an assignee or a reviewer of.' \
        'Ignored if `merge_request_dashboard` feature flag is disabled.',
      experiment: { milestone: '17.4' }

    field :recently_viewed_issues,
      resolver: Resolvers::Users::RecentlyViewedIssuesResolver,
      description: 'Most-recently viewed issues for the current user.',
      experiment: { milestone: '17.9' }
  end
  # rubocop:enable Graphql/AuthorizeTypes
end

::Types::CurrentUserType.prepend_mod
