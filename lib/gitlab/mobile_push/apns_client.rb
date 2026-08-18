# frozen_string_literal: true

module Gitlab
  module MobilePush
    # Thin wrapper around the apnotic gem using APNs provider token (p8)
    # authentication. Credentials come from gitlab.yml (`mobile_push.apns`),
    # so instances without an Apple key (for example a local GDK) silently
    # no-op.
    class ApnsClient
      # APNs reasons after which the device token is dead and its
      # subscription should be discarded.
      BAD_TOKEN_REASONS = %w[BadDeviceToken Unregistered DeviceTokenNotForTopic].freeze

      def initialize(
        auth_key_path: Gitlab.config.mobile_push.apns.auth_key_path,
        key_id: Gitlab.config.mobile_push.apns.key_id,
        team_id: Gitlab.config.mobile_push.apns.team_id,
        topic: Gitlab.config.mobile_push.apns.topic
      )
        @auth_key_path = auth_key_path
        @key_id = key_id
        @team_id = team_id
        @topic = topic
      end

      def configured?
        [auth_key_path, key_id, team_id].all?(&:present?)
      end

      # Synchronously delivers the payload to one subscription.
      #
      # Returns :delivered, :bad_token (the token is dead and the
      # subscription should be discarded), :failed, or :skipped (no APNs
      # credentials configured). Never raises: a misconfigured key (missing,
      # unreadable, or invalid p8 file) or a transport error is tracked and
      # reported as :failed, so one bad setting cannot fail every todo batch
      # in Sidekiq.
      def push(subscription, payload)
        unless configured?
          log_skipped(subscription)
          return :skipped
        end

        response = connection_for(subscription).push(build_notification(subscription, payload))

        categorize_response(response)
      rescue StandardError => e
        drop_connection(subscription.apns_environment)
        Gitlab::ErrorTracking.track_exception(e, subscription_id: subscription.id)

        :failed
      end

      # Connections are reused per APNs environment for the lifetime of this
      # client instance (one worker execution); callers must close.
      def close
        @connections&.each_value(&:close)
        @connections = nil
      end

      private

      attr_reader :auth_key_path, :key_id, :team_id, :topic

      def connection_for(subscription)
        @connections ||= {}
        @connections[subscription.apns_environment] ||= build_connection(subscription)
      end

      # A connection that raised mid-push may be broken: keeping it memoized
      # would fail every remaining push in its APNs environment without ever
      # reconnecting, so it is evicted (and closed, so the socket does not
      # outlive the eviction) and the next push builds a fresh one.
      def drop_connection(environment)
        connection = @connections&.delete(environment)
        connection&.close
      rescue StandardError
        nil
      end

      def build_connection(subscription)
        # The gem is declared `require: false`: nothing outside this client
        # needs the APNs/HTTP2 stack, so it loads on first send only.
        require 'apnotic'

        options = {
          auth_method: :token,
          cert_path: auth_key_path,
          key_id: key_id,
          team_id: team_id
        }

        if subscription.apns_sandbox?
          Apnotic::Connection.development(options)
        else
          Apnotic::Connection.new(options)
        end
      end

      def build_notification(subscription, payload)
        notification = Apnotic::Notification.new(subscription.device_token)
        notification.topic = subscription.bundle_identifier.presence || topic
        notification.alert = {
          'title' => payload.title,
          'subtitle' => payload.subtitle,
          'body' => payload.body
        }.compact
        notification.badge = payload.badge
        notification.sound = 'default'
        notification.thread_id = payload.thread_id if payload.thread_id
        notification.apns_collapse_id = payload.collapse_id
        notification.mutable_content = true if payload.mutable_content?
        notification.custom_payload = { gitlab: payload.gitlab_data }
        notification
      end

      def categorize_response(response)
        return :failed if response.nil?
        return :delivered if response.ok?

        reason = response.body.is_a?(Hash) ? response.body['reason'] : nil

        return :bad_token if response.status.to_i == 410 || BAD_TOKEN_REASONS.include?(reason)

        :failed
      end

      def log_skipped(subscription)
        Gitlab::AppLogger.info(
          message: 'APNs credentials are not configured, skipping mobile push notification',
          class: self.class.name,
          subscription_id: subscription.id
        )
      end
    end
  end
end
