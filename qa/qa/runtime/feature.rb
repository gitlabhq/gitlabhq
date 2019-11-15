# frozen_string_literal: true

module QA
  module Runtime
    module Feature
      extend self
      extend Support::Api

      SetFeatureError = Class.new(RuntimeError)
      AuthorizationError = Class.new(RuntimeError)

      def enable(key)
        QA::Runtime::Logger.info("Enabling feature: #{key}")
        set_feature(key, true)
      end

      def disable(key)
        QA::Runtime::Logger.info("Disabling feature: #{key}")
        set_feature(key, false)
      end

      def remove(key)
        request = Runtime::API::Request.new(api_client, "/features/#{key}")
        response = delete(request.url)
        unless response.code == QA::Support::Api::HTTP_STATUS_NO_CONTENT
          raise SetFeatureError, "Deleting feature flag #{key} failed with `#{response}`."
        end
      end

      def enable_and_verify(key)
        Support::Retrier.retry_on_exception(sleep_interval: 2) do
          enable(key)

          is_enabled = false

          QA::Support::Waiter.wait(interval: 1) do
            is_enabled = enabled?(key)
          end

          raise SetFeatureError, "#{key} was not enabled!" unless is_enabled
        end
      end

      def enabled?(key)
        feature = JSON.parse(get_features).find { |flag| flag["name"] == key }
        feature && feature["state"] == "on"
      end

      private

      def api_client
        @api_client ||= begin
          if Runtime::Env.admin_personal_access_token
            Runtime::API::Client.new(:gitlab, personal_access_token: Runtime::Env.admin_personal_access_token)
          else
            user = Resource::User.fabricate_via_api! do |user|
              user.username = Runtime::User.admin_username
              user.password = Runtime::User.admin_password
            end

            unless user.admin?
              raise AuthorizationError, "Administrator access is required to enable/disable feature flags. User '#{user.username}' is not an administrator."
            end

            Runtime::API::Client.new(:gitlab, user: user)
          end
        end
      end

      def set_feature(key, value)
        request = Runtime::API::Request.new(api_client, "/features/#{key}")
        response = post(request.url, { value: value })
        unless response.code == QA::Support::Api::HTTP_STATUS_CREATED
          raise SetFeatureError, "Setting feature flag #{key} to #{value} failed with `#{response}`."
        end
      end

      def get_features
        request = Runtime::API::Request.new(api_client, "/features")
        response = get(request.url)
        response.body
      end
    end
  end
end
