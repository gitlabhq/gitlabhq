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
          type: ::GraphQL::BOOLEAN_TYPE,
          null: false,
          calls_gitaly: true,
          method: :can_merge?,
          description: 'Whether this user can merge this merge request.'

    field :can_update,
          type: ::GraphQL::BOOLEAN_TYPE,
          null: false,
          method: :can_update?,
          description: 'Whether this user can update this merge request.'

    field :review_state,
          ::Types::MergeRequestReviewStateEnum,
          null: true,
          description: 'The state of the review by this user.'

    field :reviewed,
          type: ::GraphQL::BOOLEAN_TYPE,
          null: false,
          method: :reviewed?,
          description: 'Whether this user has provided a review for this merge request.'

    field :approved,
          type: ::GraphQL::BOOLEAN_TYPE,
          null: false,
          method: :approved?,
          description: 'Whether this user has approved this merge request.'
  end
end

::Types::UserMergeRequestInteractionType.prepend_mod_with('Types::UserMergeRequestInteractionType')
