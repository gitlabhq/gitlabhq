# frozen_string_literal: true

module API
  class TrackAPIRequestFromPersonalAccessToken < ::Grape::Middleware::Base
    delegate :endpoint_id, to: :context

    def after
      token_info = ::Current.token_info
      return unless token_info.is_a?(Hash) && token_info[:token_type] == 'PersonalAccessToken'

      # NOTE: use instance_variable_get to avoid triggering lazy current_user evaluation
      user = context.instance_variable_get(:@current_user)

      return unless user
      return unless Feature.enabled?(:track_api_request_from_personal_access_token, user)

      additional_properties = {
        label: endpoint_id,
        pat_type: token_info[:pat_type],
        response_code: context.status
      }

      denied_permissions = ::Current.formatted_granular_denied_permissions
      additional_properties[:denied_permissions] = denied_permissions if denied_permissions

      ::Gitlab::InternalEvents.track_event(
        'use_pat',
        user: user,
        additional_properties: additional_properties
      )

      # Explicit nil is needed or the api call return value will be overwritten
      nil
    end
  end
end
