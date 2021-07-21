# frozen_string_literal: true

module Prometheus
  class CreateDefaultAlertsWorker
    include ApplicationWorker

    data_consistency :always

    sidekiq_options retry: 3

    feature_category :incident_management
    urgency :high
    idempotent!

    def perform(project_id)
      project = Project.find_by_id(project_id)

      return unless project

      result = ::Prometheus::CreateDefaultAlertsService.new(project: project).execute

      log_info(result.message) if result.error?
    end

    private

    def log_info(message)
      logger.info(structured_payload(message: message))
    end
  end
end
