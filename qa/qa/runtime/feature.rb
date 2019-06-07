# frozen_string_literal: true

module QA
  module Runtime
    module Feature
      extend self
      extend Support::Api

      SetFeatureError = Class.new(RuntimeError)

      def enable(key)
        QA::Runtime::Logger.info("Enabling feature: #{key}")
        set_feature(key, true)
      end

      def disable(key)
        QA::Runtime::Logger.info("Disabling feature: #{key}")
        set_feature(key, false)
      end

      private

      def api_client
        @api_client ||= Runtime::API::Client.new(:gitlab)
      end

      def set_feature(key, value)
        request = Runtime::API::Request.new(api_client, "/features/#{key}")
        response = post(request.url, { value: value })
        unless response.code == QA::Support::Api::HTTP_STATUS_CREATED
          raise SetFeatureError, "Setting feature flag #{key} to #{value} failed with `#{response}`."
        end
      end
    end
  end
end
