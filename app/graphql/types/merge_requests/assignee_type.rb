# frozen_string_literal: true

module Types
  module MergeRequests
    class AssigneeType < ::Types::UserType
      graphql_name 'MergeRequestAssignee'
      description 'A user assigned to a merge request.'

      include ::Types::MergeRequests::InteractsWithMergeRequest

      authorize :read_user
    end
  end
end
