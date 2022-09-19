# frozen_string_literal: true

module Types
  module BranchProtections
    class MergeAccessLevelType < BaseAccessLevelType # rubocop:disable Graphql/AuthorizeTypes
      graphql_name 'MergeAccessLevel'
      description 'Represents the merge access level of a branch protection.'
      accepts ::ProtectedBranch::MergeAccessLevel
    end
  end
end
