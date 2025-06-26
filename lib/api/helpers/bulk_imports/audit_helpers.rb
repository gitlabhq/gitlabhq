# frozen_string_literal: true

module API
  module Helpers
    module BulkImports
      module AuditHelpers
        def log_direct_transfer_audit_event(event_name, event_message, current_user, scope)
          ::Import::BulkImports::Audit::Auditor.new(
            event_name: event_name,
            event_message: event_message,
            current_user: current_user,
            scope: scope
          ).execute
        end
      end
    end
  end
end
