# frozen_string_literal: true

module Integrations
  class ExecuteWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    data_consistency :delayed
    sidekiq_options retry: 3
    sidekiq_options dead: false
    feature_category :integrations
    urgency :low

    worker_has_external_dependencies!

    def perform(hook_id, data)
      return if ::Gitlab::SilentMode.enabled?

      data = Gitlab::WebHooks.prepare_data(data)
      integration = Integration.find_by_id(hook_id)
      return unless integration

      begin
        integration.execute(data)
      rescue StandardError => e
        integration.log_exception(e)
      end
    end
  end
end
