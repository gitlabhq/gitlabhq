# frozen_string_literal: true

module API
  module Entities
    module Clusters
      class AgentToken < AgentTokenBasic
        expose :last_used_at
      end
    end
  end
end
