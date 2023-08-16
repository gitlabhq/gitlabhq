# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module External
        class Rules
          # Remove these two constants when FF `ci_refactor_external_rules` is removed
          ALLOWED_KEYS = Entry::Include::Rules::Rule::ALLOWED_KEYS
          ALLOWED_WHEN = Entry::Include::Rules::Rule::ALLOWED_WHEN

          InvalidIncludeRulesError = Class.new(Mapper::Error)

          def initialize(rule_hashes)
            if Feature.enabled?(:ci_refactor_external_rules)
              return unless rule_hashes

              # We must compose the include rules entry here because included
              # files are expanded before `@root.compose!` runs in Ci::Config.
              rules_entry = Entry::Include::Rules.new(rule_hashes)
              rules_entry.compose!

              raise InvalidIncludeRulesError, "include:#{rules_entry.errors.first}" unless rules_entry.valid?

              @rule_list = Build::Rules::Rule.fabricate_list(rules_entry.value)
            else
              validate(rule_hashes)

              @rule_list = Build::Rules::Rule.fabricate_list(rule_hashes)
            end
          end

          def evaluate(context)
            if @rule_list.nil?
              Result.new('always')
            elsif matched_rule = match_rule(context)
              Result.new(matched_rule.attributes[:when])
            else
              Result.new('never')
            end
          end

          private

          def match_rule(context)
            @rule_list.find { |rule| rule.matches?(nil, context) }
          end

          # Remove this method when FF `ci_refactor_external_rules` is removed
          def validate(rule_hashes)
            return unless rule_hashes.is_a?(Array)

            rule_hashes.each do |rule_hash|
              next if (rule_hash.keys - ALLOWED_KEYS).empty? && valid_when?(rule_hash)

              raise InvalidIncludeRulesError, "invalid include rule: #{rule_hash}"
            end
          end

          # Remove this method when FF `ci_refactor_external_rules` is removed
          def valid_when?(rule_hash)
            rule_hash[:when].nil? || rule_hash[:when].in?(ALLOWED_WHEN)
          end

          Result = Struct.new(:when) do
            def pass?
              self.when != 'never'
            end
          end
        end
      end
    end
  end
end
