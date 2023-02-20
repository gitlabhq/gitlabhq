# frozen_string_literal: true

# == IssuParent
#
# Used as a common ancestor for Group and Project so we can allow a polymorphic
# Types::GlobalIDType[::IssueParent] in the GraphQL API
#
# Used by Project, Group
#
module IssueParent
end
