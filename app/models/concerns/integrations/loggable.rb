# frozen_string_literal: true

module Integrations
  module Loggable
    def log_info(message, params = {})
      message = build_message(message, params)

      logger.info(message)
    end

    def log_error(message, params = {})
      message = build_message(message, params)

      logger.error(message)
    end

    def log_exception(error, params = {})
      Gitlab::ExceptionLogFormatter.format!(error, params)

      log_error(params[:message] || error.message, params)
    end

    def build_message(message, params = {})
      {
        integration_class: self.class.name,
        integration_id: id,
        project_id: project&.id,
        project_path: project&.full_path,
        Labkit::Fields::GL_ORGANIZATION_ID => organization_id_for_logging,
        message: message
      }.merge(params)
    end

    # Instance-level integrations store their own organization_id; group and
    # project-level ones inherit it from their parent.
    def organization_id_for_logging
      organization_id || parent&.organization_id
    end

    def logger
      Gitlab::IntegrationsLogger
    end
  end
end
