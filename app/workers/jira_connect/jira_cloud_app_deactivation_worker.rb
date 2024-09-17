# frozen_string_literal: true

module JiraConnect
  class JiraCloudAppDeactivationWorker # rubocop:disable Scalability/IdempotentWorker -- Some reason.
    include ApplicationWorker

    BATCH_SIZE = 1_000

    data_consistency :delayed
    queue_namespace :jira_connect
    feature_category :integrations
    urgency :low

    worker_has_external_dependencies!

    def perform(namespace_id)
      integration = Integrations::JiraCloudApp.for_group(namespace_id).first

      return unless integration

      Integrations::JiraCloudApp.transaction do
        integration.inherit_from_id = nil
        integration.deactivate!
        Integration.descendants_from_self_or_ancestors_from(integration).each_batch(of: BATCH_SIZE) do |records|
          records.update!(active: false)
        end
      end
    end
  end
end
