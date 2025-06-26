# frozen_string_literal: true

module Import
  module BulkImports
    module Audit
      class Auditor
        attr_reader :event_name, :event_message, :current_user, :scope

        def initialize(event_name:, event_message:, current_user:, scope:)
          @event_name = event_name
          @event_message = event_message
          @current_user = current_user
          @scope = scope
        end

        def execute
          return if silent_admin_export?

          ::Gitlab::Audit::Auditor.audit(
            name: event_name,
            author: current_user,
            scope: scope,
            target: scope,
            message: event_message
          )
        end

        private

        def silent_admin_export?
          export_event? &&
            current_user.can_admin_all_resources? &&
            ::Gitlab::CurrentSettings.silent_admin_exports_enabled?
        end

        def export_event?
          event_name == Events::EXPORT_INITIATED ||
            event_name == Events::EXPORT_DOWNLOADED ||
            event_name == Events::EXPORT_BATCH_DOWNLOADED
        end
      end
    end
  end
end
