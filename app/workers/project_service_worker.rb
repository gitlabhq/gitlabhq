# frozen_string_literal: true

class ProjectServiceWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  data_consistency :always
  sidekiq_options retry: 3
  sidekiq_options dead: false
  feature_category :integrations
  urgency :low

  worker_has_external_dependencies!

  def perform(hook_id, data)
    data = data.with_indifferent_access
    integration = Integration.find_by_id(hook_id)
    return unless integration

    begin
      integration.execute(data)
    rescue StandardError => error
      integration.log_exception(error)
    end
  end
end
