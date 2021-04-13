# frozen_string_literal: true

module Types
  module Boards
    class AssigneeWildcardIdEnum < BaseEnum
      graphql_name 'AssigneeWildcardId'
      description 'Assignee ID wildcard values'

      value 'NONE', 'No assignee is assigned.'
      value 'ANY', 'An assignee is assigned.'
    end
  end
end
