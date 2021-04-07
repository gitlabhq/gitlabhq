# frozen_string_literal: true

module Types
  class MergeRequestReviewStateEnum < BaseEnum
    graphql_name 'MergeRequestReviewState'
    description 'State of a review of a GitLab merge request.'

    from_rails_enum(::MergeRequestReviewer.states,
                    description: "The merge request is %{name}.")
  end
end
