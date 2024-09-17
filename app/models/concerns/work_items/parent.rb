# frozen_string_literal: true

# == WorkItemParent
#
# Used as a common ancestor for Group and Project so we can allow a polymorphic
# Types::GlobalIDType[::WorkItems::Parent] in the GraphQL API
#
# Used by Project, Group
#
module WorkItems
  module Parent
  end
end
