# frozen_string_literal: true

module Gitlab
  module Environment
    def self.hostname
      @hostname ||= ENV['HOSTNAME'] || Socket.gethostname
    end

    def self.qa_user_agent
      ENV['GITLAB_QA_USER_AGENT']
    end
  end
end
