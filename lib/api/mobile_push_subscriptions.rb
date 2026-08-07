# frozen_string_literal: true

module API
  class MobilePushSubscriptions < ::API::Base
    feature_category :notifications
    urgency :low

    before do
      authenticate!
      not_found! unless Feature.enabled?(:mobile_push_registration_api, current_user)
    end

    resource :user do
      desc 'Register a mobile device for push notifications' do
        detail 'Idempotently registers the calling user\'s device token for APNs push notifications. ' \
          'Re-registering an existing token refreshes its attributes; a token previously owned by ' \
          'another user is reassigned to the calling user.'
        success Entities::MobilePushSubscription
        failure [[400, 'Bad Request'], [401, 'Unauthorized'], [404, 'Not Found']]
        tags %w[mobile_push_subscriptions]
      end
      params do
        requires :device_token, type: String, desc: 'The hexadecimal APNs device token'
        # `platform` and `payload_mode` declare no `default:` on purpose: Grape
        # fills defaults into `params`, so `declared_params(include_missing:
        # false)` would carry them into every re-registration and reset a
        # stored value (for example `id_only` back to `full`). The column
        # defaults own the initial values instead. `apns_environment` keeps its
        # default because it is part of the lookup identity, not an attribute.
        optional :platform, type: String, values: %w[ios], desc: 'The device platform'
        optional :apns_environment, type: String, values: %w[production sandbox], default: 'production',
          desc: 'The APNs environment the token was issued for'
        optional :bundle_id, type: String, desc: 'The application bundle identifier'
        optional :device_name, type: String, desc: 'A human-readable device name'
        optional :app_version, type: String, desc: 'The installed application version'
        optional :locale, type: String, desc: 'The device locale'
        optional :payload_mode, type: String, values: %w[full id_only],
          desc: 'Whether notifications carry the full content or only identifiers'
      end
      route_setting :authorization, permissions: :create_mobile_push_subscription, boundary_type: :user
      post 'push_subscriptions' do
        attributes = declared_params(include_missing: false)
        # The public param keeps the platform's own name (`bundle_id`); the
        # column is `bundle_identifier` because `*_id` columns are reserved
        # for foreign keys by the schema conventions.
        attributes[:bundle_identifier] = attributes.delete(:bundle_id) if attributes.key?(:bundle_id)

        result = ::Notifications::MobileDevicePushSubscriptions::RegisterService.new(
          user: current_user,
          device_token: attributes.delete(:device_token),
          apns_environment: attributes.delete(:apns_environment),
          attributes: attributes
        ).execute

        # The service reports failures through the subscription's validation
        # errors, e.g. a reassignment blocked by the per-user subscription cap.
        render_validation_error!(result.payload[:subscription]) if result.error?

        present result.payload[:subscription], with: Entities::MobilePushSubscription
      end

      desc 'Unregister a mobile device from push notifications' do
        detail 'Removes the calling user\'s push subscriptions for the given device token.'
        success code: 204
        failure [[400, 'Bad Request'], [401, 'Unauthorized'], [404, 'Not Found']]
        tags %w[mobile_push_subscriptions]
      end
      params do
        requires :device_token, type: String, desc: 'The hexadecimal APNs device token'
      end
      route_setting :authorization, permissions: :delete_mobile_push_subscription, boundary_type: :user
      # The token rides in the request body rather than the URL path: path
      # segments land in `api_json.log` and proxy access logs in cleartext,
      # while body parameters are masked by `filter_parameters` (`/token$/i`),
      # consistent with the registration request and with the column being
      # encrypted at rest.
      delete 'push_subscriptions' do
        result = ::Notifications::MobileDevicePushSubscriptions::UnregisterService.new(
          user: current_user,
          device_token: params[:device_token]
        ).execute

        not_found!('MobileDevicePushSubscription') if result.error?

        no_content!
      end
    end
  end
end
