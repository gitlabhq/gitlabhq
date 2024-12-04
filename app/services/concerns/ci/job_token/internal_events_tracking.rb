# frozen_string_literal: true

module Ci
  module JobToken
    module InternalEventsTracking
      include Gitlab::InternalEventsTracking

      def track_job_token_scope_setting_changes(ci_cd_settings, user)
        scope_change = ci_cd_settings.previous_changes[:inbound_job_token_scope_enabled]
        if scope_change == [false, true]
          track_internal_event(
            'enable_inbound_job_token_scope',
            user: user,
            project: ci_cd_settings.project
          )
        elsif scope_change == [true, false]
          track_internal_event(
            'disable_inbound_job_token_scope',
            user: user,
            project: ci_cd_settings.project
          )
        end
      end
    end
  end
end
