# frozen_string_literal: true

module JiraConnectInstallations
  class DestroyService
    def self.execute(installation, jira_connect_base_path, jira_connect_uninstalled_event_path)
      new(installation, jira_connect_base_path, jira_connect_uninstalled_event_path).execute
    end

    def initialize(installation, jira_connect_base_path, jira_connect_uninstalled_event_path)
      @installation = installation
      @jira_connect_base_path = jira_connect_base_path
      @jira_connect_uninstalled_event_path = jira_connect_uninstalled_event_path
    end

    def execute
      if @installation.instance_url.present?
        JiraConnect::ForwardEventWorker.perform_async(@installation.id, @jira_connect_base_path, @jira_connect_uninstalled_event_path)
        return true
      end

      @installation.destroy
    end
  end
end
