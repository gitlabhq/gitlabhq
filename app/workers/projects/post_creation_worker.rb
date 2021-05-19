# frozen_string_literal: true

module Projects
  class PostCreationWorker
    include ApplicationWorker

    sidekiq_options retry: 3

    feature_category :source_code_management
    tags :exclude_from_kubernetes
    idempotent!

    def perform(project_id)
      project = Project.find_by_id(project_id)

      return unless project

      create_prometheus_service(project)
    end

    private

    def create_prometheus_service(project)
      service = project.find_or_initialize_service(::PrometheusService.to_param)

      # If the service has already been inserted in the database, that
      # means it came from a template, and there's nothing more to do.
      return if service.persisted?

      return unless service.prometheus_available?

      service.save!
    rescue ActiveRecord::RecordInvalid => e
      Gitlab::ErrorTracking.track_exception(e, extra: { project_id: project.id })
    end
  end
end
