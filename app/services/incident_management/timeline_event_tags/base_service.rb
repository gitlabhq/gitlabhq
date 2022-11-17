# frozen_string_literal: true

module IncidentManagement
  module TimelineEventTags
    class BaseService
      def allowed?
        user&.can?(:admin_incident_management_timeline_event_tag, project)
      end

      def success(timeline_event_tag)
        ServiceResponse.success(payload: { timeline_event_tag: timeline_event_tag })
      end

      def error(message)
        ServiceResponse.error(message: message)
      end

      def error_no_permissions
        error(_('You have insufficient permissions to manage timeline event tags for this project'))
      end

      def error_in_save(timeline_event_tag)
        error(timeline_event_tag.errors.full_messages.to_sentence)
      end
    end
  end
end
