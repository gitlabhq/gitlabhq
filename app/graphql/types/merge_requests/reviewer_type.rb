# frozen_string_literal: true

module Types
  module MergeRequests
    class ReviewerType < ::Types::UserType
      graphql_name 'MergeRequestReviewer'
      description 'A user assigned to a merge request as a reviewer.'

      include ::Types::MergeRequests::InteractsWithMergeRequest

      authorize :read_user
    end
  end
end
