# frozen_string_literal: true

module Gitlab
  module Audit
    module Logging
      # Persists audit events built by AuditEvents::BuildService, each of which is
      # already an instance of the model backing its scope.
      #
      # @return [Array] the persisted events, or [] when the write failed
      def persist_events(events, audit_operation)
        return [] if events.blank?

        events.group_by(&:class).flat_map { |event_class, scoped_events| log_events(event_class, scoped_events) }
      rescue ActiveRecord::RecordInvalid => e
        ::Gitlab::ErrorTracking.track_exception(e, audit_operation: audit_operation)
        []
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
    end
  end
end

Gitlab::Audit::Logging.prepend_mod
