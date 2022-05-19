# frozen_string_literal: true

module API
  module Entities
    module Clusters
      class AgentTokenWithToken < AgentToken
        expose :token
      end
    end
  end
end
