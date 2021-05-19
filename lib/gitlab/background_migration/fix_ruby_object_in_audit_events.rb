# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Remove serialized Ruby object in audit_events
    class FixRubyObjectInAuditEvents
      def perform(start_id, stop_id)
      end
    end
  end
end

Gitlab::BackgroundMigration::FixRubyObjectInAuditEvents.prepend_mod_with('Gitlab::BackgroundMigration::FixRubyObjectInAuditEvents')
