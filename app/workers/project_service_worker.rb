# frozen_string_literal: true

class ProjectServiceWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  data_consistency :always

  sidekiq_options retry: 3

  sidekiq_options dead: false
  feature_category :integrations
  worker_has_external_dependencies!

  def perform(hook_id, data)
    data = data.with_indifferent_access
    integration = Integration.find(hook_id)
    integration.execute(data)
  rescue StandardError => error
    integration_class = integration&.class&.name || "Not Found"
    Gitlab::ErrorTracking.log_exception(error, integration_class: integration_class)
  end
end
