# frozen_string_literal: true

module ProjectServicesLoggable
  def log_info(message, params = {})
    message = build_message(message, params)

    logger.info(message)
  end

  def log_error(message, params = {})
    message = build_message(message, params)

    logger.error(message)
  end

  def build_message(message, params = {})
    {
      service_class: self.class.name,
      project_id: project&.id,
      project_path: project&.full_path,
      message: message
    }.merge(params)
  end

  def logger
    Gitlab::ProjectServiceLogger
  end
end
