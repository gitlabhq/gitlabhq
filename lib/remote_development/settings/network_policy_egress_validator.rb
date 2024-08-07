# frozen_string_literal: true

module RemoteDevelopment
  module Settings
    class NetworkPolicyEgressValidator
      include Messages

      def self.validate(context)
        unless context.fetch(:requested_setting_names).include?(:network_policy_egress)
          return Gitlab::Fp::Result.ok(context)
        end

        context => {
          settings: {
            network_policy_egress: Array => network_policy_egress,
          }
        }
        network_policy_egress = network_policy_egress.map do |element|
          next element unless element.is_a?(Hash)

          element.deep_stringify_keys
        end
        errors = validate_against_schema(network_policy_egress)

        if errors.none?
          Gitlab::Fp::Result.ok(context)
        else
          Gitlab::Fp::Result.err(SettingsNetworkPolicyEgressValidationFailed.new(
            details: errors.join(". ")))
        end
      end

      # @param [Array] array_to_validate
      # @return [Array]
      def self.validate_against_schema(array_to_validate)
        schema = {
          "type" => "array",
          "items" => {
            "type" => "object",
            "required" => %w[
              allow
            ],
            "properties" => {
              "allow" => {
                "type" => "string"
              },
              "except" => {
                "type" => "array",
                "items" => {
                  "type" => "string"
                }
              }
            }
          }
        }

        schemer = JSONSchemer.schema(schema)
        errors = schemer.validate(array_to_validate)
        errors.map { |error| JSONSchemer::Errors.pretty(error) }
      end

      private_class_method :validate_against_schema
    end
  end
end
