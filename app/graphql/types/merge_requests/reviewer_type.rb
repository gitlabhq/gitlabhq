# frozen_string_literal: true

module Types
  module MergeRequests
    class ReviewerType < ::Types::UserType
      include FindClosest
      include ::Types::MergeRequests::InteractsWithMergeRequest

      graphql_name 'MergeRequestReviewer'
      description 'A user assigned to a merge request as a reviewer.'
      authorize :read_user
    end
  end
end
