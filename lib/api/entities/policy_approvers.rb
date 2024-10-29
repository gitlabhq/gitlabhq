# frozen_string_literal: true

module API
  module Entities
    class PolicyApprovers < Grape::Entity
      expose :users, using: 'API::Entities::UserBasic'
      expose :groups, using: 'API::Entities::PublicGroupDetails'
      expose :all_groups, using: 'API::Entities::PublicGroupDetails'
      expose :roles, documentation: { type: 'string', is_array: true }
    end
  end
end
