# frozen_string_literal: true

require "json"
require "time"

module Gitlab
  module PolicyStore
    # Compiles one entry of a policy's authored `rules`, a plain jsonb hash, into a
    # Rego program in the `package governance` namespace exposing `violation`.
    class RuleTranspiler
      include RegoPackage

      AUTHORED_WALL_CLOCK_FORMAT = "%Y-%m-%dT%H:%M:%S"

      EMITTED_TIMESTAMP_FORMAT = "%Y-%m-%dT%H:%M:%SZ"
      EMITTED_TIMESTAMP_PATTERN = /\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z\z/

      # Anchored at both ends, so a bound `Time.iso8601` would read leniently is refused as
      # the wrong shape rather than reaching a later guard with a message about its meaning.
      # Case-insensitive because RFC 3339 lets both the separator and the `Z` be lowercase.
      AUTHORED_INSTANT_PATTERN = /\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?(?:Z|[+-]\d{2}:?\d{2})\z/i

      # A refusal has to cost less than the parse it prevents, and `Time.iso8601` accepts
      # a year of any width.
      MAX_AUTHORED_TIMESTAMP_LENGTH = 64

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
        when "calendar" then program(calendar_statements)
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

        declared_package = declared_in(value)
        unless declared_package == PACKAGE_NAME
          invalid!("custom rule must declare `package #{PACKAGE_NAME}`, found #{reported_value(declared_package)}")
        end

        value
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

      def calendar_statements
        invalid!("calendar rule requires at least one window") if windows.empty?

        [violation_rule(details: calendar_details, conditions: calendar_conditions)]
      end

      def calendar_details
        %({"rule_index": #{rule_index}, "window": freeze_window.name})
      end

      # The window is bound with `:=` rather than by `some freeze_window in`, because `some`
      # requires that its name be undeclared, so a `custom` rule declaring `freeze_window`
      # at package level fails the whole merged `violation` query under Regorus 0.11. The
      # window array itself is inlined here rather than named at package level, which two
      # merged calendar rules would redeclare.
      def calendar_conditions
        [
          "freeze_window := #{freeze_windows_literal}[_]",
          "input.environment.tier in freeze_window.tiers",
          "input.evaluated_at >= freeze_window.starts_at",
          "input.evaluated_at < freeze_window.ends_at",
          'msg := sprintf("deployment blocked by freeze window %s (%s to %s)", ' \
            '[freeze_window.name, freeze_window.starts_at, freeze_window.ends_at])'
        ]
      end

      def freeze_windows_literal
        entries = windows.map { |window| "\t\t#{window_literal(window)}," }

        "[\n#{entries.join("\n")}\n\t]"
      end

      def window_literal(window)
        %({"name": #{rego_string(window[:name])}, "tiers": #{rego_array(window[:tiers])}, ) +
          %("starts_at": #{rego_string(window[:starts_at])}, "ends_at": #{rego_string(window[:ends_at])}})
      end

      def windows
        @windows ||= authored_windows.each_with_index.map { |window, index| normalized_window(window, index) }.uniq
      end

      def authored_windows
        configuration["windows"].is_a?(Array) ? configuration["windows"] : []
      end

      def normalized_window(window, index)
        invalid!("calendar window #{index} must be an object") unless window.is_a?(Hash)

        name = window["name"]
        invalid!("calendar window #{index} requires a name") if unusable_string?(name)

        tiers = sorted_unique_strings_from(window["tiers"])
        invalid!("calendar window #{reported_value(name)} requires at least one tier") if tiers.empty?

        starts_at = normalized_timestamp(window["starts_at"], field: "starts_at", window_name: name)
        ends_at = normalized_timestamp(window["ends_at"], field: "ends_at", window_name: name)
        invalid!("calendar window #{reported_value(name)} ends before it starts") unless starts_at < ends_at

        { name: name, tiers: tiers, starts_at: starts_at, ends_at: ends_at }
      end

      def normalized_timestamp(raw_value, field:, window_name:)
        parsed = parsed_timestamp(raw_value, field: field, window_name: window_name)

        # `Time.iso8601` rolls an out-of-range component forward, so June 31 parses as
        # July 1 and a window authored for it would silently start a day late. Compared
        # case-insensitively, since RFC 3339 lets the separator be authored lowercase.
        unless raw_value.downcase.start_with?(parsed.strftime(AUTHORED_WALL_CLOCK_FORMAT).downcase)
          invalid!("calendar window #{reported_value(window_name)} #{field} names a date or time that " \
            "does not exist: #{reported_value(raw_value)}")
        end

        unless parsed.subsec.zero?
          invalid!("calendar window #{reported_value(window_name)} #{field} carries sub-second precision " \
            "the emitted comparison cannot represent: #{reported_value(raw_value)}")
        end

        emitted = parsed.getutc.strftime(EMITTED_TIMESTAMP_FORMAT)
        return emitted if EMITTED_TIMESTAMP_PATTERN.match?(emitted)

        invalid!("calendar window #{reported_value(window_name)} #{field} is outside the range the emitted " \
          "comparison can order: #{reported_value(raw_value)}")
      end

      def parsed_timestamp(raw_value, field:, window_name:)
        invalid!("calendar window #{reported_value(window_name)} requires #{field}") unless raw_value.is_a?(String)

        if raw_value.length > MAX_AUTHORED_TIMESTAMP_LENGTH
          invalid!("calendar window #{reported_value(window_name)} #{field} is longer than any instant: " \
            "#{reported_value(raw_value)}")
        end

        # The `Encoding::CompatibilityError` from matching an ASCII pattern against this is
        # not an `ArgumentError`, so the rescue below cannot turn it into a refusal.
        unless raw_value.ascii_only?
          invalid!("calendar window #{reported_value(window_name)} #{field} must be ASCII to be an " \
            "ISO 8601 instant, not #{raw_value.encoding}")
        end

        unless AUTHORED_INSTANT_PATTERN.match?(raw_value)
          invalid!("calendar window #{reported_value(window_name)} #{field} must be an RFC 3339 instant " \
            "such as `2026-12-24T00:00:00Z`: #{reported_value(raw_value)}")
        end

        Time.iso8601(raw_value)
      rescue ArgumentError
        invalid!("calendar window #{reported_value(window_name)} has an unparsable #{field}: " \
          "#{reported_value(raw_value)}")
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
        "{#{rego_strings(members)}}"
      end

      def rego_array(members)
        "[#{rego_strings(members)}]"
      end

      def rego_strings(members)
        members.map { |member| rego_string(member) }.join(", ")
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
