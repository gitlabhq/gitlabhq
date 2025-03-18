# frozen_string_literal: true

module Types
  class UserMergeRequestInteractionType < BaseObject
    graphql_name 'UserMergeRequestInteraction'
    description <<~MD
      Information about a merge request given a specific user.

      This object has two parts to its state: a `User` and a `MergeRequest`. All
      fields relate to interactions between the two entities.
    MD

    authorize :read_merge_request

    field :can_merge,
      type: ::GraphQL::Types::Boolean,
      null: false,
      calls_gitaly: true,
      method: :can_merge?,
      description: 'Whether the user can merge the merge request.'

    field :can_update,
      type: ::GraphQL::Types::Boolean,
      null: false,
      method: :can_update?,
      description: 'Whether the user can update the merge request.'

    field :review_state,
      ::Types::MergeRequestReviewStateEnum,
      null: true,
      description: 'State of the review by the user.'

    field :reviewed,
      type: ::GraphQL::Types::Boolean,
      null: false,
      method: :reviewed?,
      description: 'Whether the user has provided a review for the merge request.'

    field :approved,
      type: ::GraphQL::Types::Boolean,
      null: false,
      method: :approved?,
      description: 'Whether the user has approved the merge request.'
  end
end

::Types::UserMergeRequestInteractionType.prepend_mod_with('Types::UserMergeRequestInteractionType')
