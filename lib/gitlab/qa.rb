# frozen_string_literal: true

module Gitlab
  module Qa
    def self.user_agent
      ENV['GITLAB_QA_USER_AGENT']
    end

    def self.request?(request_user_agent)
      return false unless Gitlab.com?
      return false unless request_user_agent.present?
      return false unless user_agent.present?

      ActiveSupport::SecurityUtils.secure_compare(request_user_agent, user_agent)
    end
  end
end
