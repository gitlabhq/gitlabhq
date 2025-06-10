# frozen_string_literal: true

module Ci
  module JobTokenScope
    module ScopeEventTracking
      def track_event(scope, action_name = 'created')
        ::Gitlab::InternalEvents.track_event(
          'action_on_job_token_allowlist_entry',
          project: scope.source_project,
          additional_properties: {
            label: scope.id.to_s,
            property: scope.class.name.demodulize.underscore,
            action_name: action_name,
            default_permissions: scope.default_permissions?.to_s,
            self_referential: (scope.source_project_id == scope.try(:target_project_id)).to_s
          }
        )
      end
    end
  end
end
