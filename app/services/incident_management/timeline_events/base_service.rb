# frozen_string_literal: true

module IncidentManagement
  module TimelineEvents
    class BaseService
      include Gitlab::Utils::UsageData

      def allowed?
        user&.can?(:admin_incident_management_timeline_event, incident)
      end

      def success(timeline_event)
        ServiceResponse.success(payload: { timeline_event: timeline_event })
      end

      def error(message)
        ServiceResponse.error(message: message)
      end

      def error_no_permissions
        error(_('You have insufficient permissions to manage timeline events for this incident'))
      end

      def error_in_save(timeline_event)
        error(timeline_event.errors.full_messages.to_sentence)
      end

      def track_timeline_event(event, project)
        namespace = project.namespace
        track_usage_event(event, user.id)

        Gitlab::Tracking.event(
          self.class.to_s,
          event,
          project: project,
          namespace: namespace,
          user: user,
          label: 'redis_hll_counters.incident_management.incident_management_total_unique_counts_monthly',
          context: [Gitlab::Tracking::ServicePingContext.new(data_source: :redis_hll, event: event).to_context]
        )
      end

      def auto_create_predefined_tags(new_tags)
        new_tags = new_tags.map(&:downcase)

        tags_to_create = TimelineEventTag::PREDEFINED_TAGS.select { |tag| tag.downcase.in?(new_tags) }

        tags_to_create.each do |name|
          project.incident_management_timeline_event_tags.create(name: name)
        end
      end
    end
  end
end
