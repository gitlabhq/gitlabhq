# frozen_string_literal: true

module Gitlab
  module Ci
    module Build
      class Rules
        include ::Gitlab::Utils::StrongMemoize

        Result = Struct.new(:when, :start_in)

        def initialize(rule_hashes, default_when = 'on_success')
          @rule_list    = Rule.fabricate_list(rule_hashes)
          @default_when = default_when
        end

        def evaluate(pipeline, build)
          if @rule_list.nil?
            Result.new(@default_when)
          elsif matched_rule = match_rule(pipeline, build)
            Result.new(
              matched_rule.attributes[:when] || @default_when,
              matched_rule.attributes[:start_in]
            )
          else
            Result.new('never')
          end
        end

        private

        def match_rule(pipeline, build)
          @rule_list.find { |rule| rule.matches?(pipeline, build) }
        end
      end
    end
  end
end
