# frozen_string_literal: true

require "json"

module Gitlab
  module PolicyStore
    class RuleTranspiler
      module Emitters
        class Base
          include InvalidatesViaCallable

          def initialize(rule_index:, value:, invalid:, reported_value:)
            @rule_index = rule_index
            @value = value
            @invalid = invalid
            @reported_value = reported_value
          end

          private

          attr_reader :rule_index, :value

          def configuration
            @configuration ||= value.is_a?(Hash) ? value : {}
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

          def violation_rule(details:, conditions:)
            "violation contains {\"msg\": msg, \"details\": #{details}} if {\n#{indent(conditions)}\n}"
          end
        end
      end
    end
  end
end
