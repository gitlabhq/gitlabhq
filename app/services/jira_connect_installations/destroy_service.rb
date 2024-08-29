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

      # rubocop:disable Database/AvoidUsingPluckWithoutLimit, CodeReuse/ActiveRecord -- Limit of 100 max per page is defined in kaminari config
      subscriptions_namespace_ids = @installation.subscriptions.pluck(:namespace_id)
      # rubocop:enable Database/AvoidUsingPluckWithoutLimit, CodeReuse/ActiveRecord

      return false unless @installation.destroy

      deactivate_jira_cloud_app_integrations(subscriptions_namespace_ids)
      true
    end

    def deactivate_jira_cloud_app_integrations(subscriptions_namespace_ids)
      subscriptions_namespace_ids.each do |namespace_id|
        JiraConnect::JiraCloudAppDeactivationWorker.perform_async(namespace_id)
      end
    end
  end
end
