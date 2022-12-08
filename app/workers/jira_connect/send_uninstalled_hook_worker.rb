# frozen_string_literal: true

module JiraConnect
  class SendUninstalledHookWorker
    include ApplicationWorker

    data_consistency :delayed
    queue_namespace :jira_connect
    feature_category :integrations
    urgency :low

    idempotent!

    worker_has_external_dependencies!

    def perform(installation_id, instance_url)
      installation = JiraConnectInstallation.find_by_id(installation_id)

      JiraConnectInstallations::ProxyLifecycleEventService.execute(installation, :uninstalled, instance_url)
    end
  end
end
