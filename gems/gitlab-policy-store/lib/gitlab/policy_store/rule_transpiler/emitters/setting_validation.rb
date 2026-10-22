# frozen_string_literal: true

module Gitlab
  module PolicyStore
    class RuleTranspiler
      module Emitters
        # Emits a violation when the subject's setting differs from the value the
        # policy requires.
        #
        # An absent value is skipped rather than violated: a setting the evaluation
        # context leaves out is one the subject cannot carry, and a violation there
        # would recur on every evaluation with no write able to clear it. `object.get`
        # is what tells an absent key apart from a stored `false`. The skip is
        # therefore also fail-open: `squash_option` (a nullable column) and
        # `secret_push_protection_enabled` (dropped on an unlicensed tier) are the
        # two settings the context can omit, and a policy pinning either reports
        # nothing at all on a subject that omits it.
        #
        # An unclearable violation is still reachable from the other direction: the
        # authored value is validated for its own type but never against the
        # setting's declared one, so a string `"true"` compared against a stored
        # boolean can never match. The settings catalog that closes that gap lands
        # with https://gitlab.com/gitlab-org/gitlab/-/work_items/630153.
        class SettingValidation < Base
          # Every trigger this rule can pair with carries a project, so the subject the
          # settings hang off is fixed.
          SUBJECT_ROOT = "project"
          SETTINGS_SEGMENT = "settings"

          # Room for the indent and the fixed text the emitted lines carry around the
          # setting name and the value, doubled so the refusal stays fail-closed if
          # either line widens.
          SETTING_LINE_PREFIX_COLUMNS = 256

          private_constant :SUBJECT_ROOT, :SETTINGS_SEGMENT, :SETTING_LINE_PREFIX_COLUMNS

          def setting_validation_statements
            refuse_oversized_line!

            [violation_rule(details: setting_details, conditions: setting_conditions)]
          end

          private

          def setting_details
            fields = [
              %("rule_index": #{rule_index}),
              %("path": #{rego_string(setting_path)}),
              %("expected": #{rego_string(expected)}),
              %("actual": #{actual})
            ]

            "{#{fields.join(', ')}}"
          end

          # `msg` names the bare setting where the detail names the dotted path. That is
          # deliberate: it is the human-readable short form, and ViolationMessage drops it
          # entirely whenever a path is present, so the two never appear in one sentence.
          def setting_conditions
            [
              %(#{actual} := object.get(input, [#{rego_strings(setting_lookup_path)}], null)),
              "#{actual} != null",
              "#{actual} != #{rego_string(expected)}",
              %(msg := sprintf("setting %s must be %v", [#{rego_string(setting)}, #{rego_string(expected)}]))
            ]
          end

          # Scoped to the rule, because a `custom` rule in the same policy declaring the
          # same name at package level would fail the whole merged `violation` query.
          def actual
            "setting_actual_#{rule_index}"
          end

          def setting_lookup_path
            [SUBJECT_ROOT, SETTINGS_SEGMENT, setting]
          end

          # The dotted context path the violation reports. It is the same path the condition
          # reads, so what a consumer is told was checked cannot drift from what was actually
          # read. GOVERN-017 fixes this notation as the contract between a policy and an
          # enforcement point:
          # https://gitlab.com/gitlab-org/architecture/govern/design-doc/-/merge_requests/29
          def setting_path
            setting_lookup_path.join(".")
          end

          # The engine refuses a line wider than MAX_LINE_COLUMNS. The widest line this
          # emitter produces is the violation head, which carries the dotted path, the
          # expected value and the actual-value variable; the sprintf line carries the
          # same expected value beside the shorter bare setting name, so the one budget
          # covers both. Only a `custom` rule is validated on its own, so a rule that
          # crosses the limit reaches the engine as part of the merged program and reads
          # as an engine fault rather than a refusal.
          def refuse_oversized_line!
            width = rego_string(setting_path).bytesize + rego_string(expected).bytesize + SETTING_LINE_PREFIX_COLUMNS
            return if width <= MAX_LINE_COLUMNS

            invalid!("setting_validation rule is too long for the engine's line limit")
          end

          def setting
            return @setting if defined?(@setting)

            raw = configuration["setting"]
            invalid!("setting_validation rule requires a setting name") if unusable_string?(raw)

            @setting = raw.strip
          end

          # Authored under `value`, reported under `expected`. The two words are deliberately
          # different: an author writes what a policy requires, a violation reports what was
          # required of the subject. Govern::PolicyEngine::ViolationDetails::EXPECTED_KEY is
          # what reads it back today, through ViolationMessage#clause.
          # https://gitlab.com/groups/gitlab-org/-/work_items/23462#note_3961259915
          def expected
            return @expected if defined?(@expected)

            raw = configuration["value"]
            unless raw == true || raw == false || raw.is_a?(Numeric) || raw.is_a?(String)
              invalid!("setting_validation rule requires a boolean, string, or number value")
            end

            invalid!("setting_validation rule requires a non-blank value") if raw.is_a?(String) && unusable_string?(raw)

            @expected = raw.is_a?(String) ? raw.strip : raw
          end
        end
      end
    end
  end
end
