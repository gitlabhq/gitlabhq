# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # This cop checks for `Timecop.freeze` usage in specs.
      #
      # @example
      #
      #   # bad
      #   Timecop.freeze(Time.current) { example.run }
      #
      #   # good
      #   freeze_time(Time.current) { example.run }
      #
      class TimecopFreeze < RuboCop::Cop::Cop
        include MatchRange
        MESSAGE = 'Do not use `Timecop.freeze`, use `freeze_time` instead. ' \
                  'See https://gitlab.com/gitlab-org/gitlab/-/issues/214432 for more info.'

        def_node_matcher :timecop_freeze?, <<~PATTERN
          (send (const nil? :Timecop) :freeze ?_)
        PATTERN

        def on_send(node)
          return unless timecop_freeze?(node)

          add_offense(node, location: :expression, message: MESSAGE)
        end

        def autocorrect(node)
          -> (corrector) do
            each_match_range(node.source_range, /^(Timecop\.freeze)/) do |match_range|
              corrector.replace(match_range, 'freeze_time')
            end
          end
        end
      end
    end
  end
end
