# frozen_string_literal: true

module API
  module Entities
    module Ci
      class RunnerControllerTokenWithToken < RunnerControllerToken
        expose :token, documentation: { type: 'String' }
      end
    end
  end
end
