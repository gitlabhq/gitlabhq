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
        set_and_verify(key, enable: true)
      end

      def disable_and_verify(key)
        set_and_verify(key, enable: false)
      end

      def enabled?(key)
        feature = JSON.parse(get_features).find { |flag| flag["name"] == key }
        feature && feature["state"] == "on"
      end

      def get_features
        request = Runtime::API::Request.new(api_client, "/features")
        response = get(request.url)
        response.body
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

      # Change a feature flag and verify that the change was successful
      # Arguments:
      #   key: The feature flag to set (as a string)
      #   enable: `true` to enable the flag, `false` to disable it
      def set_and_verify(key, enable:)
        Support::Retrier.retry_on_exception(sleep_interval: 2) do
          enable ? enable(key) : disable(key)

          is_enabled = nil

          QA::Support::Waiter.wait_until(sleep_interval: 1) do
            is_enabled = enabled?(key)
            is_enabled == enable
          end

          raise SetFeatureError, "#{key} was not #{enable ? 'enabled' : 'disabled'}!" unless is_enabled == enable

          QA::Runtime::Logger.info("Successfully #{enable ? 'enabled' : 'disabled'} and verified feature flag: #{key}")
        end
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
