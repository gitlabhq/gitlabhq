# frozen_string_literal: true

class ProjectServiceWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  sidekiq_options dead: false
  feature_category :integrations
  worker_has_external_dependencies!

  def perform(hook_id, data)
    data = data.with_indifferent_access
    service = Service.find(hook_id)
    service.execute(data)
  rescue => error
    service_class = service&.class&.name || "Not Found"
    logger.error class: self.class.name, service_class: service_class, message: error.message
  end
end
