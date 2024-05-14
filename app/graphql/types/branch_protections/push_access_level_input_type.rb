# frozen_string_literal: true

module Types
  module BranchProtections
    class PushAccessLevelInputType < BaseAccessLevelInputType
      graphql_name 'PushAccessLevelInput'
      description 'Defines which user roles, users, deploy keys, or groups can push to a protected branch.'

      argument :deploy_key_id, Types::GlobalIDType[DeployKey],
        prepare: ->(global_id, _ctx) { global_id.model_id.to_i },
        required: false,
        description: 'Deploy key assigned to the access level.'
    end
  end
end
