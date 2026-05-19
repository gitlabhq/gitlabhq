# frozen_string_literal: true

require 'rubocop-rspec'

module RuboCop
  module Cop
    module RSpec
      # Checks for `wait_for_requests` and `wait_for_all_requests` usage in
      # feature specs. Instead, assert on a UI change to ensure the request
      # has completed.
      #
      # These helpers are not reliable since these just check that there are no in-flight
      # requests. If the check runs before the request has been initiated, it may pass before
      # the request is made.
      #
      # @example
      #   # bad
      #   click 'some button'
      #   wait_for_requests
      #
      #   # good
      #   click 'some button'
      #   expect(page).to have_content('Updated')
      class AvoidWaitForRequests < RuboCop::Cop::Base
        MESSAGE = 'Avoid `%{method}` in feature specs. ' \
          'Instead, assert on a UI change to ensure the request has completed. ' \
          'See https://docs.gitlab.com/development/testing_guide/frontend_testing/#assertions.'

        RESTRICT_ON_SEND = %i[wait_for_requests wait_for_all_requests].freeze

        # @!method wait_for_requests_call?(node)
        def_node_matcher :wait_for_requests_call?, <<~PATTERN
          (send nil? ${:wait_for_requests :wait_for_all_requests} ...)
        PATTERN

        def on_send(node)
          method = wait_for_requests_call?(node)
          return unless method

          add_offense(node, message: format(MESSAGE, method: method))
        end
        alias_method :on_csend, :on_send
      end
    end
  end
end
