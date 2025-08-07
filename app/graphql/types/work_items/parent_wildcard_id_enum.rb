# frozen_string_literal: true

module Types
  module WorkItems
    class ParentWildcardIdEnum < BaseEnum
      graphql_name 'WorkItemParentWildcardId'
      description 'Parent ID wildcard values'

      value 'NONE', 'No parent is assigned.'
      value 'ANY', 'Any parent is assigned.'
    end
  end
end
