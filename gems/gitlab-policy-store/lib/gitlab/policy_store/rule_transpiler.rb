# frozen_string_literal: true

require "json"

module Gitlab
  module PolicyStore
    # Compiles one entry of a policy's authored `rules`, a plain jsonb hash, into a
    # Rego program in the `package governance` namespace exposing `violation`.
    class RuleTranspiler
      PACKAGE_NAME = "governance"

      RULE_PRELUDE = "package #{PACKAGE_NAME}".freeze

      # Nothing bounds the size of an authored rule, so a refusal names a value only
      # up to this much of it.
      MAX_REPORTED_VALUE_LENGTH = 64

      def initialize(rule, rule_index: 0)
        @rule = rule
        @rule_index = rule_index.to_i
      end

      def transpile
        invalid!("expected an object with a type") unless rule.is_a?(Hash)

        case rule_type
        when "custom" then custom_program
        when "environment" then program(environment_statements)
        else invalid!("unsupported rule type #{reported_value(source['type'])}")
        end
      end

      private

      attr_reader :rule, :rule_index

      def program(statements)
        "#{RULE_PRELUDE}\n\n#{[header, *statements].join("\n\n")}\n"
      end

      def header
        "# rule #{rule_index}: #{rule_type}"
      end

      def custom_program
        invalid!("custom rule requires Rego source in value") unless value.is_a?(String)

        # Checked ahead of the emptiness test because the program is stored as authored,
        # so nothing downstream re-encodes it, and the package scan below cannot match a
        # String whose encoding the regexp is incompatible with.
        invalid!("custom rule source must be UTF-8, found #{value.encoding}") unless utf8_compatible?(value)

        invalid!("custom rule requires Rego source in value") if unusable_string?(value)

        declared_package = declared_package_in(value)
        unless declared_package == PACKAGE_NAME
          invalid!("custom rule must declare `package #{PACKAGE_NAME}`, found #{reported_value(declared_package)}")
        end

        value
      end

      def declared_package_in(rego_source)
        first_statement = rego_source.each_line.lazy
          .map { |line| line.sub(/#.*/, "").strip }
          .find { |line| !line.empty? }

        first_statement.to_s[/\Apackage[ \t]+(\S+)\z/, 1]
      end

      def environment_statements
        conditions = environment_conditions

        invalid!("environment rule requires at least one of names or tiers") if conditions.empty?

        [violation_rule(details: environment_details, conditions: conditions + [environment_message])]
      end

      # `rule_index` rides on the violation rather than only on the header comment
      # because `violation` is a set: once a policy's programs are combined into one
      # module, two rules emitting identical objects would deduplicate into one.
      def environment_details
        fields = [
          %("rule_index": #{rule_index}),
          %("environment_id": input.environment.id),
          %("environment_name": input.environment.name)
        ]

        "{#{fields.join(', ')}}"
      end

      def environment_conditions
        conditions = []
        conditions << "input.environment.name in #{rego_set(environment_names)}" if environment_names.any?
        conditions << "input.environment.tier in #{rego_set(environment_tiers)}" if environment_tiers.any?

        conditions
      end

      def environment_message
        'msg := sprintf("deployment to %s is blocked by this policy", [input.environment.name])'
      end

      def violation_rule(details:, conditions:)
        "violation contains {\"msg\": msg, \"details\": #{details}} if {\n#{indent(conditions)}\n}"
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

      def configuration
        @configuration ||= value.is_a?(Hash) ? value : {}
      end

      def environment_names
        @environment_names ||= sorted_unique_strings_from(configuration["names"])
      end

      def environment_tiers
        @environment_tiers ||= sorted_unique_strings_from(configuration["tiers"])
      end

      def rego_set(members)
        "{#{members.map { |member| rego_string(member) }.join(', ')}}"
      end

      # `valid_encoding?` is true for a binary string carrying high bytes, so the
      # refusal has to come from the encode itself, or the caller gets a 500 where
      # every other refusal is a 400.
      def rego_string(member)
        member.to_json
      rescue JSON::GeneratorError
        invalid!("value cannot be encoded as UTF-8: #{reported_value(member)}")
      end

      def sorted_unique_strings_from(raw_value)
        return [] unless raw_value.is_a?(Array)

        raw_value.reject { |item| unusable_string?(item) }.uniq.sort
      end

      # A dummy encoding (UTF-16 carrying a BOM, ISO-2022-JP) has to be refused before
      # anything reads the text, because `String#strip` raises on one.
      def unusable_string?(raw_value)
        return true unless raw_value.is_a?(String)
        return true if raw_value.encoding.dummy?

        !raw_value.valid_encoding? || raw_value.strip.empty?
      end

      def utf8_compatible?(text)
        text.encoding == Encoding::UTF_8 || text.ascii_only?
      end

      def indent(lines)
        lines.map { |line| "\t#{line}" }.join("\n")
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
