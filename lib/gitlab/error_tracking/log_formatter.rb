# frozen_string_literal: true

module Gitlab
  module ErrorTracking
    class LogFormatter
      # Note: all the accesses to Raven's contexts here are to keep the
      # backward-compatibility to Sentry's built-in integrations. In future,
      # they can be removed.
      def generate_log(exception, context_payload)
        payload = {}

        Gitlab::ExceptionLogFormatter.format!(exception, payload)
        append_user_to_log!(payload, context_payload)
        append_tags_to_log!(payload, context_payload)
        append_extra_to_log!(payload, context_payload)

        payload
      end

      private

      def append_user_to_log!(payload, context_payload)
        user_context = Raven.context.user.merge(context_payload[:user])
        user_context.each do |key, value|
          payload["user.#{key}"] = value
        end
      end

      def append_tags_to_log!(payload, context_payload)
        tags_context = Raven.context.tags.merge(context_payload[:tags])
        tags_context.each do |key, value|
          payload["tags.#{key}"] = value
        end
      end

      def append_extra_to_log!(payload, context_payload)
        extra = Raven.context.extra.merge(context_payload[:extra])
        extra = extra.except(:server)

        # The extra value for sidekiq is a hash whose keys are strings.
        if extra[:sidekiq].is_a?(Hash) && extra[:sidekiq].key?('args')
          sidekiq_extra = extra.delete(:sidekiq)
          sidekiq_extra['args'] = Gitlab::ErrorTracking::Processor::SidekiqProcessor.loggable_arguments(
            sidekiq_extra['args'], sidekiq_extra['class']
          )
          payload["extra.sidekiq"] = sidekiq_extra
        end

        extra.each do |key, value|
          payload["extra.#{key}"] = value
        end
      end
    end
  end
end
