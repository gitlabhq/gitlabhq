# frozen_string_literal: true

module Projects
  class PostCreationWorker
    include ApplicationWorker

    data_consistency :always

    sidekiq_options retry: 3

    feature_category :source_code_management
    idempotent!

    def perform(project_id)
      project = Project.find_by_id(project_id)

      return unless project

      create_prometheus_integration(project)
    end

    private

    def create_prometheus_integration(project)
      integration = project.find_or_initialize_integration(::Integrations::Prometheus.to_param)

      # If the service has already been inserted in the database, that
      # means it came from a template, and there's nothing more to do.
      return if integration.persisted?

      return unless integration.prometheus_available?

      integration.save!
    rescue ActiveRecord::RecordInvalid => e
      Gitlab::ErrorTracking.track_exception(e, extra: { project_id: project.id })
    end

    def create_incident_management_timeline_event_tags(project)
      tags = project.incident_management_timeline_event_tags.pluck_names
      start_time_name = ::IncidentManagement::TimelineEventTag::START_TIME_TAG_NAME
      end_time_name = ::IncidentManagement::TimelineEventTag::END_TIME_TAG_NAME

      project.incident_management_timeline_event_tags.new(name: start_time_name) unless tags.include?(start_time_name)

      project.incident_management_timeline_event_tags.new(name: end_time_name) unless tags.include?(end_time_name)

      project.save!
    rescue StandardError => e
      Gitlab::ErrorTracking.track_exception(e, extra: { project_id: project.id })
    end
  end
end
