# frozen_string_literal: true

module IncidentManagement
  module TimelineEvents
    class BaseService
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
    end
  end
end
