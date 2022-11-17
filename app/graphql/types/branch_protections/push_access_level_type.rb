# frozen_string_literal: true

module Types
  module BranchProtections
    class PushAccessLevelType < BaseAccessLevelType # rubocop:disable Graphql/AuthorizeTypes
      graphql_name 'PushAccessLevel'
      description 'Defines which user roles, users, or groups can push to a protected branch.'
      accepts ::ProtectedBranch::PushAccessLevel
    end
  end
end
