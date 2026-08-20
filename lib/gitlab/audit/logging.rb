# frozen_string_literal: true

module Gitlab
  module Audit
    module Logging
      # Persists audit events that are already scoped model instances, as built by
      # AuditEvents::BuildService.
      #
      # @return [Array] the persisted events, or [] when the write failed
      def persist_events(events, audit_operation)
        return [] if events.blank?

        events.group_by(&:class).flat_map { |event_class, scoped_events| log_events(event_class, scoped_events) }
      rescue ActiveRecord::RecordInvalid => e
        ::Gitlab::ErrorTracking.track_exception(e, audit_operation: audit_operation)
        []
      end

      # Copies legacy AuditEvent records into the scoped tables. Only the deprecated
      # AuditEventService still builds those.
      def log_to_new_tables(events, audit_operation)
        return [] if events.blank?

        scoped_events = events.map do |event|
          model = ::AuditEvents::BuildService::ENTITY_TYPE_TO_MODEL.fetch(event.entity_type.to_s)

          model.new(build_event_attributes(event))
        end

        persist_events(scoped_events, audit_operation)
      end

      private

      def log_events(event_class, events)
        if events.one?
          [events.first.tap(&:save!)]
        else
          event_ids = event_class.bulk_insert!(events, returns: :ids)
          event_class.id_in(event_ids)
        end
      end

      def build_event_attributes(event)
        attributes = {
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
        }.merge(scope_attributes(event))

        # Reuse the legacy row's id so both tables reference the same event. A failed
        # legacy write leaves no id, so the scoped table falls back to its own sequence.
        attributes[:id] = event.id if event.id.present?

        attributes
      end

      def scope_attributes(event)
        column = ::AuditEvents::BuildService::ENTITY_TYPE_TO_SCOPE_COLUMN[event.entity_type.to_s]
        return {} unless column

        { column => event.entity_id }
      end
    end
  end
end

Gitlab::Audit::Logging.prepend_mod
