# frozen_string_literal: true

module API
  module Entities
    class DeployTokenWithToken < Entities::DeployToken
      expose :token
    end
  end
end
