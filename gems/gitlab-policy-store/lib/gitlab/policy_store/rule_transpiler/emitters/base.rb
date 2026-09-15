# frozen_string_literal: true

require "json"

module Gitlab
  module PolicyStore
    class RuleTranspiler
      module Emitters
        class Base
          include InvalidatesViaCallable

          # Mirrors regorus's default max_col (DEFAULT_MAX_COL), which GLAZ inherits by not
          # overriding it via set_policy_length_config. Lives upstream, so nothing catches drift.
          MAX_LINE_COLUMNS = 1024

          # Room for the indent and `input.environment.name in ` ahead of a set on its line.
          # The worst prefix is a tab (4 engine columns) and `input.environment.name in ` (26).
          SET_LINE_PREFIX_COLUMNS = 32

          # A wrapped member sits on its own line behind two tabs, which the engine counts as
          # 8 columns; doubled to 16 so the refusal stays fail-closed if that prefix widens.
          MEMBER_LINE_PREFIX_COLUMNS = 16

          private_constant :SET_LINE_PREFIX_COLUMNS, :MEMBER_LINE_PREFIX_COLUMNS

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

          # The engine refuses a line over MAX_LINE_COLUMNS, which a few dozen environment names
          # on one line would exceed, so a set that would is spread one member per line instead.
          def rego_set(members)
            rendered_members = members.map { |member| rego_string(member) }
            inline = "{#{rendered_members.join(', ')}}"
            return inline if inline.bytesize + SET_LINE_PREFIX_COLUMNS <= MAX_LINE_COLUMNS

            lines = members.zip(rendered_members).map do |member, rendered|
              if rendered.bytesize + MEMBER_LINE_PREFIX_COLUMNS > MAX_LINE_COLUMNS
                invalid!("value is too long for the engine's line limit: #{reported_value(member)}")
              end

              "\t\t#{rendered}"
            end

            "{\n#{lines.join(",\n")}\n\t}"
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
