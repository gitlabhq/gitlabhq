# frozen_string_literal: true

class ProjectServiceWorker
  include ApplicationWorker

  sidekiq_options dead: false

  def perform(hook_id, data)
    data = data.with_indifferent_access
    service = Service.find(hook_id)
    service.execute(data)
  rescue => error
    service_class = service&.class&.name || "Not Found"
    logger.error class: self.class.name, service_class: service_class, message: error.message
  end
end
