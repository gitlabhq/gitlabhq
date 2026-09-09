# frozen_string_literal: true

module Gitlab
  module PolicyStore
    # Compiles one entry of a policy's authored `rules`, a plain jsonb hash, into a
    # Rego program in the `package governance` namespace exposing `violation`.
    class RuleTranspiler
      include RegoPackage

      # Nothing bounds the size of an authored rule, so a refusal names a value only
      # up to this much of it.
      MAX_REPORTED_VALUE_LENGTH = 64

      def initialize(rule, rule_index: 0, max_projected_bytes: nil)
        @rule = rule
        @rule_index = rule_index.to_i
        @max_projected_bytes = max_projected_bytes
      end

      def transpile
        invalid!("expected an object with a type") unless rule.is_a?(Hash)

        case rule_type
        when "custom" then Emitters::Custom.new(**emitter_kwargs).custom_program
        when "environment" then program(Emitters::Environment.new(**emitter_kwargs).environment_statements)
        when "calendar"
          calendar = Emitters::Calendar.new(**emitter_kwargs, max_projected_bytes: max_projected_bytes)
          program(calendar.calendar_statements)
        else invalid!("unsupported rule type #{reported_value(source['type'])}")
        end
      end

      private

      attr_reader :rule, :rule_index, :max_projected_bytes

      def emitter_kwargs
        { rule_index: rule_index, value: value, invalid: method(:invalid!), reported_value: method(:reported_value) }
      end

      def program(statements)
        "#{RULE_PRELUDE}\n\n#{[header, *statements].join("\n\n")}\n"
      end

      def header
        "# rule #{rule_index}: #{rule_type}"
      end

      def source
        @source ||= JsonValue.deep_stringify(rule)
      end

      # Compared rather than stringified, so a value that is superlinear to render
      # reaches the refusal without being rendered.
      def rule_type
        source["type"]
      end

      def value
        source["value"]
      end

      def invalid!(message)
        raise PolicyStore::ValidationError, "rule #{rule_index}: #{message}"
      end

      def reported_value(raw_value)
        return "nil" if raw_value.nil?
        return raw_value.class.to_s unless raw_value.is_a?(String)
        return raw_value.inspect if raw_value.length <= MAX_REPORTED_VALUE_LENGTH

        "#{raw_value[0, MAX_REPORTED_VALUE_LENGTH].inspect} (#{raw_value.length} characters)"
      end
    end
  end
end
