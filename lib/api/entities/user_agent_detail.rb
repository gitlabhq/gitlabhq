# frozen_string_literal: true

module API
  module Entities
    class UserAgentDetail < Grape::Entity
      expose :user_agent, documentation: { type: 'string', example: 'AppleWebKit/537.36' }
      expose :ip_address, documentation: { type: 'string', example: '127.0.0.1' }
      expose :submitted, as: :akismet_submitted, documentation: { type: 'boolean', example: false }
    end
  end
end
