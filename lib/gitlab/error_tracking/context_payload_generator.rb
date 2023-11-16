# frozen_string_literal: true

module Gitlab
  module ErrorTracking
    class ContextPayloadGenerator
      def self.generate(exception, extra = {}, tags = {})
        new.generate(exception, extra, tags)
      end

      def generate(exception, extra = {}, tags = {})
        {
          extra: extra_payload(exception, extra),
          tags: tags_payload(tags),
          user: user_payload
        }
      end

      private

      def extra_payload(exception, extra)
        inline_extra = exception.try(:sentry_extra_data)
        if inline_extra.present? && inline_extra.is_a?(Hash)
          extra = extra.merge(inline_extra)
        end

        sanitize_request_parameters(extra)
      end

      def sanitize_request_parameters(parameters)
        filter = ActiveSupport::ParameterFilter.new(::Rails.application.config.filter_parameters)
        filter.filter(parameters)
      end

      def tags_payload(tags)
        tags.merge(
          extra_tags_from_env.merge!(
            program: Gitlab.process_name,
            locale: I18n.locale,
            feature_category: current_context['meta.feature_category'],
            Labkit::Correlation::CorrelationId::LOG_KEY.to_sym => Labkit::Correlation::CorrelationId.current_id
          )
        )
      end

      def user_payload
        {
          username: current_context['meta.user']
        }
      end

      # Static tags that are set on application start
      def extra_tags_from_env
        Gitlab::Json.parse(ENV.fetch('GITLAB_SENTRY_EXTRA_TAGS', '{}')).to_hash
      rescue StandardError => e
        Gitlab::AppLogger.debug("GITLAB_SENTRY_EXTRA_TAGS could not be parsed as JSON: #{e.class.name}: #{e.message}")

        {}
      end

      def current_context
        # In case Gitlab::ErrorTracking is used when the app starts
        return {} unless defined?(::Gitlab::ApplicationContext)

        ::Gitlab::ApplicationContext.current.to_h
      end
    end
  end
end
