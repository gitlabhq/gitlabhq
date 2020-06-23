# frozen_string_literal: true

module API
  module Entities
    class DeployKeysProject < Grape::Entity
      expose :deploy_key, merge: true, using: Entities::DeployKey
      expose :can_push
    end
  end
end
