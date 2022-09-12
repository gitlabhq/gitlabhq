# frozen_string_literal: true

module Types
  module BranchProtections
    class PushAccessLevelType < BaseAccessLevelType # rubocop:disable Graphql/AuthorizeTypes
      graphql_name 'PushAccessLevel'
      description 'Represents the push access level of a branch protection.'
      accepts ::ProtectedBranch::PushAccessLevel
    end
  end
end
