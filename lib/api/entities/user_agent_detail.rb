# frozen_string_literal: true

module API
  module Entities
    class UserAgentDetail < Grape::Entity
      expose :user_agent
      expose :ip_address
      expose :submitted, as: :akismet_submitted
    end
  end
end
