# frozen_string_literal: true

module API
  module Entities
    class UserAgentDetail < Grape::Entity
      expose :user_agent, documentation: { type: 'String', example: 'AppleWebKit/537.36' }
      expose :ip_address, documentation: { type: 'String', example: '127.0.0.1' }
      expose :submitted, as: :akismet_submitted, documentation: { type: 'Boolean', example: false }
    end
  end
end
