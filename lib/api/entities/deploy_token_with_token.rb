# frozen_string_literal: true

module API
  module Entities
    class DeployTokenWithToken < Entities::DeployToken
      expose :token, documentation: { type: 'string', example: 'jMRvtPNxrn3crTAGukpZ' }
    end
  end
end
