# frozen_string_literal: true

module API
  module Entities
    class DeployKeyWithUser < Entities::SSHKeyWithUser
      expose :deploy_keys_projects
    end
  end
end
