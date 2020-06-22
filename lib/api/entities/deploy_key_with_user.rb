# frozen_string_literal: true

module API
  module Entities
    class DeployKeyWithUser < Entities::DeployKey
      expose :user, using: Entities::UserPublic
      expose :deploy_keys_projects
    end
  end
end
