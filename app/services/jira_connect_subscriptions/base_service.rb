# frozen_string_literal: true

module JiraConnectSubscriptions
  class BaseService < ::BaseService
    attr_accessor :jira_connect_installation, :current_user, :params

    def initialize(jira_connect_installation, user = nil, params = {})
      @jira_connect_installation = jira_connect_installation
      @current_user = user
      @params = params.dup
    end
  end
end
