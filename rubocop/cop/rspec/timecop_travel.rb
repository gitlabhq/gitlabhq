# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # This cop checks for `Timecop.travel` usage in specs.
      #
      # @example
      #
      #   # bad
      #   Timecop.travel(1.day.ago) { create(:issue) }
      #
      #   # good
      #   travel_to(1.day.ago) { create(:issue) }
      #
      class TimecopTravel < RuboCop::Cop::Cop
        include MatchRange
        MESSAGE = 'Do not use `Timecop.travel`, use `travel_to` instead. ' \
                  'See https://gitlab.com/gitlab-org/gitlab/-/issues/214432 for more info.'

        def_node_matcher :timecop_travel?, <<~PATTERN
          (send (const nil? :Timecop) :travel _)
        PATTERN

        def on_send(node)
          return unless timecop_travel?(node)

          add_offense(node, location: :expression, message: MESSAGE)
        end

        def autocorrect(node)
          -> (corrector) do
            each_match_range(node.source_range, /^(Timecop\.travel)/) do |match_range|
              corrector.replace(match_range, 'travel_to')
            end
          end
        end
      end
    end
  end
end
