# frozen_string_literal: true

# The Rails and Rack session stores allow developers to store arbitrary
# Ruby objects in the Hash, which gets serialized to Redis. However,
# serializing objects may lead to multi-version incompatibilities
# (https://docs.gitlab.com/ee/development/multi_version_compatibility.html)
# because there is no guarantee that the Ruby object is present in an
# older version.
#
# To safeguard against this problem, this patch checks that objects
# stored in the session are in an allow list. Note that these checks are
# restricted to test and development environments at the moment. Only
# add to the allow list if you know that the object should be handled
# gracefully in a mixed deployment.
return unless Rails.env.test? || Rails.env.development?

module Rack
  module Session
    module Abstract
      class SessionHash
        module BlockRubyObjectSerialization
          ALLOWED_OBJECTS = [
            Symbol, String, Integer, Float, NilClass, TrueClass, FalseClass, ActiveSupport::SafeBuffer,
            # Used in app/controllers/import/bitbucket_controller.rb
            ActiveSupport::Duration, ActiveSupport::TimeWithZone,
            # Used in ee/app/controllers/groups/omniauth_callbacks_controller.rb
            OmniAuth::AuthHash, OmniAuth::AuthHash::InfoHash, OneLogin::RubySaml::Attributes,
            OneLogin::RubySaml::Response
          ].freeze

          def []=(key, value)
            unless safe_object?(value)
              # rubocop:disable Gitlab/DocumentationLinks/HardcodedUrl
              raise "Session attempted to store type #{value.class} with key '#{key}': #{value.inspect}.\n" \
                    "Serializing novel Ruby objects can cause uninitialized constants in mixed deployments.\n" \
                    "See https://docs.gitlab.com/ee/development/multi_version_compatibility.html"
              # rubocop:enable Gitlab/DocumentationLinks/HardcodedUrl
            end

            super
          end

          private

          def safe_object?(value)
            return allowed_mock?(value) if Rails.env.test? && value.is_a?(RSpec::Mocks::InstanceVerifyingDouble)

            case value
            when Array
              value.all? { |entry| safe_object?(entry) }
            when Hash
              safe_hash?(value)
            else
              ALLOWED_OBJECTS.include?(value.class)
            end
          end

          def safe_hash?(value)
            value.each do |key, val|
              return false unless safe_object?(key)
              return false unless safe_object?(val)
            end
          end

          def allowed_mock?(value)
            doubled_module = value.to_s

            # We don't have access to the @doubled_module variable, but the output
            # string will be in the form: "#[InstanceDouble(OneLogin::RubySaml::Response) (anonymous)]"
            ALLOWED_OBJECTS.any? { |allowed| doubled_module.include?("InstanceDouble(#{allowed})") }
          end
        end

        prepend BlockRubyObjectSerialization
      end
    end
  end
end

ActionDispatch::Request::Session.prepend(Rack::Session::Abstract::SessionHash::BlockRubyObjectSerialization)
