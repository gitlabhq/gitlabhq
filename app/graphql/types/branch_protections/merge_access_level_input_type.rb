# frozen_string_literal: true

module Types
  module BranchProtections
    class MergeAccessLevelInputType < BaseAccessLevelInputType
      graphql_name 'MergeAccessLevelInput'
      description 'Defines which user roles, users, or groups can merge into a protected branch.'
    end
  end
end
