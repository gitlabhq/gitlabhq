# frozen_string_literal: true

module Types
  module MergeRequests
    class AssigneeType < ::Types::UserType
      include FindClosest
      include ::Types::MergeRequests::InteractsWithMergeRequest

      graphql_name 'MergeRequestAssignee'
      description 'A user assigned to a merge request.'
      authorize :read_user
    end
  end
end
