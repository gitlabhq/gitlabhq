# frozen_string_literal: true

module Types
  module MergeRequests
    class DashboardListTypeEnum < BaseEnum
      graphql_name 'MergeRequestsDashboardListType'
      description 'Values for merge request dashboard list type'

      value 'ACTION_BASED', 'Action based list rendering.', value: 'action_based'
      value 'ROLE_BASED', 'Role based list rendering.', value: 'role_based'
    end
  end
end
