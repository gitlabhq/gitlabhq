# frozen_string_literal: true

require 'active_support/core_ext/object/blank'

module QA
  module Runtime
    class Feature
      class << self
        # Documentation: https://docs.gitlab.com/ee/api/features.html

        include Support::Api

        SetFeatureError = Class.new(RuntimeError)
        AuthorizationError = Class.new(RuntimeError)
        UnknownScopeError = Class.new(RuntimeError)

        def remove(key)
          request = Runtime::API::Request.new(api_client, "/features/#{key}")
          response = delete(request.url)
          unless response.code == QA::Support::Api::HTTP_STATUS_NO_CONTENT
            raise SetFeatureError, "Deleting feature flag #{key} failed with `#{response}`."
          end
        end

        def enable(key, **scopes)
          set_and_verify(key, enable: true, **scopes)
        end

        def disable(key, **scopes)
          set_and_verify(key, enable: false, **scopes)
        end

        def enabled?(key, **scopes)
          feature = JSON.parse(get_features).find { |flag| flag['name'] == key.to_s }
          feature && (feature['state'] == 'on' || feature['state'] == 'conditional' && scopes.present? && enabled_scope?(feature['gates'], scopes))
        end

        private

        def api_client
          @api_client ||= Runtime::API::Client.as_admin
        rescue Runtime::API::Client::AuthorizationError => e
          raise AuthorizationError, "Administrator access is required to enable/disable feature flags. #{e.message}"
        end

        def enabled_scope?(gates, scopes)
          scopes.each do |key, value|
            case key
            when :project, :group, :user
              actors = gates.filter { |i| i['key'] == 'actors' }.first['value']
              break actors.include?("#{key.to_s.capitalize}:#{value.id}")
            when :feature_group
              groups = gates.filter { |i| i['key'] == 'groups' }.first['value']
              break groups.include?(value)
            else
              raise UnknownScopeError, "Unknown scope: #{key}"
            end
          end
        end

        def get_features
          request = Runtime::API::Request.new(api_client, '/features')
          response = get(request.url)
          response.body
        end

        # Change a feature flag and verify that the change was successful
        # Arguments:
        #   key: The feature flag to set (as a string)
        #   enable: `true` to enable the flag, `false` to disable it
        #   scopes: Any scope (user, project, group) to restrict the change to
        def set_and_verify(key, enable:, **scopes)
          msg = "#{enable ? 'En' : 'Dis'}abling feature: #{key}"
          msg += " for scope \"#{scopes_to_s(scopes)}\"" if scopes.present?
          QA::Runtime::Logger.info(msg)

          Support::Retrier.retry_on_exception(sleep_interval: 2) do
            set_feature(key, enable, scopes)

            is_enabled = nil

            QA::Support::Waiter.wait_until(sleep_interval: 1) do
              is_enabled = enabled?(key, scopes)
              is_enabled == enable || !enable && scopes.present?
            end

            if is_enabled == enable
              QA::Runtime::Logger.info("Successfully #{enable ? 'en' : 'dis'}abled and verified feature flag: #{key}")
            else
              raise SetFeatureError, "#{key} was not #{enable ? 'en' : 'dis'}abled!" if enable

              QA::Runtime::Logger.warn("Feature flag scope was removed but the flag is still enabled globally.")
            end
          end
        end

        def set_feature(key, value, **scopes)
          scopes[:project] = scopes[:project].full_path if scopes.key?(:project)
          scopes[:group] = scopes[:group].full_path if scopes.key?(:group)
          scopes[:user] = scopes[:user].username if scopes.key?(:user)
          request = Runtime::API::Request.new(api_client, "/features/#{key}")
          response = post(request.url, scopes.merge({ value: value }))
          unless response.code == QA::Support::Api::HTTP_STATUS_CREATED
            raise SetFeatureError, "Setting feature flag #{key} to #{value} failed with `#{response}`."
          end
        end

        def scopes_to_s(**scopes)
          key = scopes.each_key.first
          s = "#{key}: "
          case key
          when :project, :group
            s += scopes[key].full_path
          when :user
            s += scopes[key].username
          when :feature_group
            s += scopes[key]
          else
            raise UnknownScopeError, "Unknown scope: #{key}"
          end

          s
        end
      end
    end
  end
end
