# frozen_string_literal: true

module Types
  module MergeRequests
    class NegatedMergeRequestFilterInputType < BaseInputObject
      # Matches the name the type had when `Gitlab::Graphql::NegatableArguments` generated it.
      graphql_name 'MergeRequestsResolverNegatedParams'

      argument :approved_by, [GraphQL::Types::String],
        required: false,
        as: :approved_by_usernames,
        description: 'Filters merge requests to exclude any that are approved by usernames in the given array.'
      argument :assignee_usernames, [GraphQL::Types::String],
        as: :assignee_username,
        required: false,
        description: 'Filters merge requests to exclude any that are assigned to the usernames in the given array.'
      argument :author_username, GraphQL::Types::String,
        required: false,
        description: 'Filters merge requests to exclude any that are authored by the given user.'
      argument :label_name, [GraphQL::Types::String],
        required: false,
        description: 'Filters merge requests to exclude any that have the labels provided in the given array.'
      argument :labels, [GraphQL::Types::String],
        as: :label_name,
        required: false,
        description: 'Filters merge requests to exclude any that have the labels provided in the given array.',
        deprecated: { reason: 'Use `labelName`', milestone: '17.7' }
      argument :milestone_title, GraphQL::Types::String,
        required: false,
        description: 'Filters merge requests to those not in the given milestone.'
      argument :my_reaction_emoji, GraphQL::Types::String,
        required: false,
        description: 'Filters merge requests to those without the given reaction from the authenticated user.'
      argument :only_reviewer, GraphQL::Types::Boolean,
        required: false,
        description: 'Filters out merge requests to those that do not have the reviewer as the only assigned reviewer.',
        experiment: { milestone: '17.11' }
      argument :release_tag, GraphQL::Types::String,
        required: false,
        description: 'Filters merge requests to those without the given release tag.'
      argument :review_states, [::Types::MergeRequestReviewStateEnum],
        required: false,
        description: 'Filters merge requests to those where a reviewer does not have the provided state.',
        experiment: { milestone: '17.9' }
      argument :reviewer_username, GraphQL::Types::String,
        required: false,
        description: 'Filters merge requests to those not reviewed by the given user.'
      argument :source_branches, [GraphQL::Types::String],
        required: false,
        as: :source_branch,
        description: 'Filters merge requests to exclude the source branch names provided in the given array.'
      argument :target_branches, [GraphQL::Types::String],
        required: false,
        as: :target_branch,
        description: 'Filters merge requests to exclude the target branch names provided in the given array.'
    end
  end
end
