# frozen_string_literal: true

module Types
  module BranchProtections
    class MergeAccessLevelType < BaseAccessLevelType # rubocop:disable Graphql/AuthorizeTypes
      graphql_name 'MergeAccessLevel'
      description 'Defines which user roles, users, or groups can merge into a protected branch.'
      accepts ::ProtectedBranch::MergeAccessLevel
    end
  end
end
