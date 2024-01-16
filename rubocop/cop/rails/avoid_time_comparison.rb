# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Checks for time comparison.
      # For more information see: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/133520
      #
      # @example
      #   # bad
      #   datetime > Time.now
      #   Time.current < datetime
      #   datetime > Time.zone.now
      #
      #   # good
      #   datetime.future?
      #   datetime.future?
      #   datetime.past?
      class AvoidTimeComparison < RuboCop::Cop::Base
        MSG = 'Avoid time comparison, use `.past?` or `.future?` instead.'
        RESTRICT_ON_SEND = %i[< >].to_set.freeze

        def_node_matcher :comparison?, <<~PATTERN
          (send _ %RESTRICT_ON_SEND _)
        PATTERN

        def_node_matcher :time_now?, <<~PATTERN
           {
            (send
              (const {nil? cbase} :Time) :now)
            (send
              (send
                (const {nil? cbase} :Time) :zone) :now)
            (send
              (const {nil? cbase} :Time) :current)
          }
        PATTERN

        def on_send(node)
          return unless comparison?(node)

          arg_check = node.arguments.find { |arg| time_now?(arg) }
          receiver_check = time_now?(node.receiver)

          add_offense(node) if arg_check || receiver_check
        end
      end
    end
  end
end
