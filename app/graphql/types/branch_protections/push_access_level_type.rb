# frozen_string_literal: true

module Types
  module BranchProtections
    class PushAccessLevelType < BaseAccessLevelType # rubocop:disable Graphql/AuthorizeTypes
      graphql_name 'PushAccessLevel'
      description 'Defines which user roles, users, or groups can push to a protected branch.'
      accepts ::ProtectedBranch::PushAccessLevel

      field :deploy_key,
        Types::AccessLevels::DeployKeyType,
        null: true,
        description: 'Deploy key assigned to the access level.'
    end
  end
end
