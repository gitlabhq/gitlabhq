# frozen_string_literal: true

module Gitlab
  module Ci
    module Build
      class Rules
        include ::Gitlab::Utils::StrongMemoize

        Result = Struct.new(
          :when, :start_in, :allow_failure, :variables, :needs, :errors, :auto_cancel, :interruptible,
          keyword_init: true
        ) do
          def build_attributes
            needs_job = needs&.dig(:job)
            {
              when: self.when,
              options: { start_in: start_in }.compact,
              allow_failure: allow_failure,
              scheduling_type: (:dag if needs_job.present?),
              needs_attributes: needs_job,
              interruptible: interruptible
            }.compact
          end

          def pass?
            self.when != 'never'
          end
        end

        def initialize(rule_hashes, default_when:)
          @rule_list    = Rule.fabricate_list(rule_hashes)
          @default_when = default_when
        end

        def evaluate(pipeline, context)
          if @rule_list.nil?
            Result.new(when: @default_when)
          elsif matched_rule = match_rule(pipeline, context)
            Result.new(
              when: matched_rule.attributes[:when] || @default_when,
              start_in: matched_rule.attributes[:start_in],
              allow_failure: matched_rule.attributes[:allow_failure],
              variables: matched_rule.attributes[:variables],
              needs: matched_rule.attributes[:needs],
              auto_cancel: matched_rule.attributes[:auto_cancel],
              interruptible: matched_rule.attributes[:interruptible]
            )
          else
            Result.new(when: 'never')
          end
        rescue Rule::Clause::ParseError => e
          Result.new(when: 'never', errors: [e.message])
        end

        private

        def match_rule(pipeline, context)
          @rule_list.find { |rule| rule.matches?(pipeline, context) }
        end
      end
    end
  end
end
