# frozen_string_literal: true

module Gitlab
  module Tracking
    SNOWPLOW_NAMESPACE = 'gl'

    class << self
      def enabled?
        Gitlab::CurrentSettings.snowplow_enabled?
      end

      def event(category, action, label: nil, property: nil, value: nil, context: [], project: nil, user: nil, namespace: nil, **extra) # rubocop:disable Metrics/ParameterLists
        contexts = [Tracking::StandardContext.new(project: project, user: user, namespace: namespace, **extra).to_context, *context]

        snowplow.event(category, action, label: label, property: property, value: value, context: contexts)
        product_analytics.event(category, action, label: label, property: property, value: value, context: contexts)
      rescue StandardError => error
        Gitlab::ErrorTracking.track_and_raise_for_dev_exception(error, snowplow_category: category, snowplow_action: action)
      end

      def snowplow_options(group)
        additional_features = Feature.enabled?(:additional_snowplow_tracking, group)
        {
          namespace: SNOWPLOW_NAMESPACE,
          hostname: Gitlab::CurrentSettings.snowplow_collector_hostname,
          cookie_domain: Gitlab::CurrentSettings.snowplow_cookie_domain,
          app_id: Gitlab::CurrentSettings.snowplow_app_id,
          form_tracking: additional_features,
          link_click_tracking: additional_features
        }.transform_keys! { |key| key.to_s.camelize(:lower).to_sym }
      end

      private

      def snowplow
        @snowplow ||= Gitlab::Tracking::Destinations::Snowplow.new
      end

      def product_analytics
        @product_analytics ||= Gitlab::Tracking::Destinations::ProductAnalytics.new
      end
    end
  end
end
