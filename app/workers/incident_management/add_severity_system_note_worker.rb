# frozen_string_literal: true

module IncidentManagement
  class AddSeveritySystemNoteWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    data_consistency :always

    sidekiq_options retry: 3

    queue_namespace :incident_management
    feature_category :incident_management
    tags :exclude_from_kubernetes

    def perform(incident_id, user_id)
      return if incident_id.blank? || user_id.blank?

      incident = Issue.with_issue_type(:incident).find_by_id(incident_id)
      return unless incident

      user = User.find_by_id(user_id)
      return unless user

      SystemNoteService.change_incident_severity(incident, user)
    end
  end
end
