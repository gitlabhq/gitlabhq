# frozen_string_literal: true

module JiraConnect
  class ForwardEventWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    data_consistency :delayed
    queue_namespace :jira_connect
    feature_category :integrations
    urgency :low

    worker_has_external_dependencies!

    def perform(installation_id, base_path, event_path)
      installation = JiraConnectInstallation.find_by_id(installation_id)
      instance_url = installation&.instance_url

      installation.destroy if installation

      return if instance_url.nil?

      proxy_url = instance_url + event_path
      qsh = Atlassian::Jwt.create_query_string_hash(proxy_url, 'POST', instance_url + base_path)
      jwt = Atlassian::Jwt.encode({ iss: installation.client_key, qsh: qsh }, installation.shared_secret)

      JiraConnect::RetryRequestWorker.perform_async(proxy_url, jwt)
    end
  end
end
