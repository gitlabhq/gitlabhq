# frozen_string_literal: true

module JiraConnect
  class ForwardEventWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    data_consistency :always

    queue_namespace :jira_connect
    feature_category :integrations
    worker_has_external_dependencies!

    def perform(installation_id, base_path, event_path)
      installation = JiraConnectInstallation.find_by_id(installation_id)

      return if installation&.instance_url.nil?

      proxy_url = installation.instance_url + event_path
      qsh = Atlassian::Jwt.create_query_string_hash(proxy_url, 'POST', installation.instance_url + base_path)
      jwt = Atlassian::Jwt.encode({ iss: installation.client_key, qsh: qsh }, installation.shared_secret)

      Gitlab::HTTP.post(proxy_url, headers: { 'Authorization' => "JWT #{jwt}" })
    ensure
      installation.destroy if installation
    end
  end
end
