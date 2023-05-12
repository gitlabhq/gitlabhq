# frozen_string_literal: true

module IncidentManagement
  module UsageData
    include Gitlab::Utils::UsageData

    def track_incident_action(current_user, target, action)
      return unless target.incident_type_issue?

      event = "incident_management_#{action}"
      track_usage_event(event, current_user.id)

      namespace = target.try(:namespace)
      project = target.try(:project)

      Gitlab::Tracking.event(
        self.class.to_s,
        event,
        project: project,
        namespace: namespace,
        user: current_user,
        label: 'redis_hll_counters.incident_management.incident_management_total_unique_counts_monthly',
        context: [Gitlab::Tracking::ServicePingContext.new(data_source: :redis_hll, event: event).to_context]
      )
    end
  end
end
