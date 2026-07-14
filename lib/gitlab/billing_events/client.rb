# frozen_string_literal: true

module Gitlab
  module BillingEvents
    class Client
      BILLABLE_USAGE_SCHEMA = 'iglu:com.gitlab/billable_usage/jsonschema/1-0-3'

      REALM_MAP = {
        'saas' => 'SaaS',
        'self-managed' => 'SM',
        'dedicated' => 'Dedicated'
      }.freeze

      def self.track_billing_event(**args)
        new.track_billing_event(**args)
      end

      def track_billing_event( # rubocop:disable Metrics/ParameterLists -- billing schema has many fields
        event_type:,
        category:,
        quantity:,
        unit_of_measure:,
        namespace:,
        project: nil,
        user: nil,
        idempotency_key: nil,
        timestamp: nil,
        metadata: nil
      )
        return unless Feature.enabled?(:billing_event_tracking, :instance)

        if !quantity.is_a?(Numeric) || quantity <= 0
          return Gitlab::AppLogger.warn(
            message: 'BillingEvents: invalid quantity',
            quantity: quantity,
            event_type: event_type
          )
        end

        event_id = generate_event_id(idempotency_key)
        root_namespace = namespace&.root_ancestor

        context = build_context(
          event_id: event_id,
          event_type: event_type,
          unit_of_measure: unit_of_measure,
          quantity: quantity,
          timestamp: timestamp,
          namespace: namespace,
          root_namespace: root_namespace,
          user: user,
          project: project,
          metadata: metadata
        )

        billing_context = SnowplowTracker::SelfDescribingJson.new(
          BILLABLE_USAGE_SCHEMA,
          context
        )

        Gitlab::Tracking.billing_event(
          category,
          event_type,
          context: [billing_context]
        )

        Gitlab::AppLogger.info(
          message: 'BillingEvents: billing event tracked',
          event_type: event_type,
          event_id: event_id,
          quantity: quantity
        )

        Gitlab::InternalEvents.track_event(
          'usage_billing_event',
          category: category,
          user: user,
          namespace: namespace,
          project: project,
          additional_properties: {
            label: event_id,
            property: event_type
          }
        )

        Gitlab::AppLogger.info(
          message: 'BillingEvents: internal event tracked',
          event_type: event_type,
          event_id: event_id
        )
      rescue StandardError => e
        Gitlab::ErrorTracking.track_exception(e, event_type: event_type, event_id: event_id)
      end

      private

      def build_context( # rubocop:disable Metrics/ParameterLists -- mirrors billing schema fields
        event_id:, event_type:, unit_of_measure:, quantity:, timestamp:,
        namespace:, root_namespace:, user:, project:, metadata:
      )
        payload = {
          event_id: event_id,
          event_type: event_type,
          unit_of_measure: unit_of_measure,
          quantity: quantity,
          timestamp: (timestamp || Time.current).iso8601,
          namespace_id: namespace.id,
          root_namespace_id: root_namespace&.id,
          realm: realm,
          deployment_type: deployment_type,
          instance_id: ::Gitlab::GlobalAnonymousId.instance_id,
          unique_instance_id: ::Gitlab::GlobalAnonymousId.instance_uuid,
          instance_version: Gitlab.version_info.to_s,
          host_name: Gitlab.config.gitlab.host,
          correlation_id: ::Labkit::Correlation::CorrelationId.current_or_new_id
        }

        payload[:project_id] = project.id if project

        if user
          payload[:subject] = user.id.to_s
          payload[:subject_type] = 'User'
          payload[:global_user_id] = ::Gitlab::GlobalAnonymousId.user_id(user)
        end

        payload[:metadata] = metadata if metadata.present?

        payload.compact
      end

      def generate_event_id(idempotency_key)
        return SecureRandom.uuid if idempotency_key.blank?

        Digest::UUID.uuid_v5(::Gitlab::GlobalAnonymousId.instance_uuid, idempotency_key)
      end

      def realm
        'SM'
      end

      def deployment_type
        'self-managed'
      end
    end
  end
end

Gitlab::BillingEvents::Client.prepend_mod
