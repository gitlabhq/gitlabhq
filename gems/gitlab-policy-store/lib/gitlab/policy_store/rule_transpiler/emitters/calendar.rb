# frozen_string_literal: true

module Gitlab
  module PolicyStore
    class RuleTranspiler
      module Emitters
        class Calendar < Base
          include JsonBytesize

          def initialize(rule_index:, value:, invalid:, reported_value:, max_projected_bytes:)
            super(rule_index: rule_index, value: value, invalid: invalid, reported_value: reported_value)

            @max_projected_bytes = max_projected_bytes
          end

          def calendar_statements
            reject_oversized_windows!
            invalid!("calendar rule requires at least one window") if windows.empty?

            [violation_rule(details: calendar_details, conditions: calendar_conditions)]
          end

          private

          attr_reader :max_projected_bytes

          def reject_oversized_windows!
            return if max_projected_bytes.nil?

            projected_bytes = projected_authored_windows_bytesize
            return if projected_bytes.nil? || projected_bytes <= max_projected_bytes

            invalid!("calendar rule's windows project to #{projected_bytes} bytes, over the " \
              "maximum of #{max_projected_bytes} bytes")
          end

          def projected_authored_windows_bytesize
            total = 0

            authored_windows.uniq.each do |window|
              bytesize = json_bytesize(window)
              return nil if bytesize.nil?

              total += bytesize
              break if total > max_projected_bytes
            end

            total
          end

          def calendar_details
            %({"rule_index": #{rule_index}, "window": freeze_window.name})
          end

          # Bound with `:=` rather than `some freeze_window in`: `some` requires its name be
          # undeclared, so a `custom` rule declaring `freeze_window` at package level would
          # fail the whole merged `violation` query under Regorus 0.11.
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

          # Inlined here rather than named at package level, which two merged calendar rules
          # would redeclare.
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

            starts_at = authored_instant(window["starts_at"], field: "starts_at", window_name: name)
            ends_at = authored_instant(window["ends_at"], field: "ends_at", window_name: name)
            invalid!("calendar window #{reported_value(name)} ends before it starts") unless starts_at < ends_at

            { name: name, tiers: tiers, starts_at: starts_at, ends_at: ends_at }
          end

          def authored_instant(raw_value, field:, window_name:)
            AuthoredInstant.new(raw_value, field: field, window_name: window_name,
              invalid: method(:invalid!), reported_value: method(:reported_value)).normalized
          end
        end
      end
    end
  end
end
