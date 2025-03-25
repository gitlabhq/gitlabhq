# frozen_string_literal: true

module Gitlab
  module Audit
    module Logging
      ENTITY_TYPE_TO_CLASS = {
        'User' => ::AuditEvents::UserAuditEvent,
        'Project' => ::AuditEvents::ProjectAuditEvent,
        'Group' => ::AuditEvents::GroupAuditEvent,
        'Gitlab::Audit::InstanceScope' => ::AuditEvents::InstanceAuditEvent
      }.freeze

      def log_to_new_tables(events, audit_operation)
        return [] if events.blank?

        events.group_by(&:entity_type).flat_map do |entity_type, entity_events|
          log_events(entity_type, entity_events)
        end
      rescue ActiveRecord::RecordInvalid => e
        ::Gitlab::ErrorTracking.track_exception(e, audit_operation: audit_operation)
        []
      end

      private

      def log_events(entity_type, entity_events)
        event_class = ENTITY_TYPE_TO_CLASS[entity_type.to_s]
        if entity_events.one?
          [event_class.create!(build_event_attributes(entity_events.first))]
        else
          new_events = entity_events.map { |event| event_class.new(build_event_attributes(event)) }
          event_ids = event_class.bulk_insert!(new_events, returns: :ids)
          event_class.id_in(event_ids)
        end
      end

      def build_event_attributes(event)
        {
          id: event.id,
          created_at: event.created_at,
          author_id: event.author_id,
          target_id: event.target_id,
          event_name: event.details[:event_name],
          details: event.details,
          ip_address: event.ip_address,
          author_name: event.author_name,
          entity_path: event.entity_path,
          target_details: event.target_details,
          target_type: event.target_type
        }.merge(additional_attributes(event))
      end

      def additional_attributes(event)
        case event.entity_type
        when 'User'
          { user_id: event.entity_id }
        when 'Project'
          { project_id: event.entity_id }
        when 'Group'
          { group_id: event.entity_id }
        else
          {}
        end
      end
    end
  end
end
