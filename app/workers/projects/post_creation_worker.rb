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

      create_incident_management_timeline_event_tags(project)
    end

    def create_incident_management_timeline_event_tags(project)
      tags = project.incident_management_timeline_event_tags.pluck_names
      predefined_tags = ::IncidentManagement::TimelineEventTag::PREDEFINED_TAGS

      predefined_tags.each do |tag|
        project.incident_management_timeline_event_tags.new(name: tag) unless tags.include?(tag)
      end

      project.save!
    rescue StandardError => e
      Gitlab::ErrorTracking.track_exception(e, extra: { project_id: project.id })
    end
  end
end
