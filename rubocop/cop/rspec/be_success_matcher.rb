# frozen_string_literal: true

require 'rubocop-rspec'

module RuboCop
  module Cop
    module RSpec
      # This cop checks for `be_success` usage in controller specs
      #
      # @example
      #
      #   # bad
      #   it "responds with success" do
      #     expect(response).to be_success
      #   end
      #
      #   it { is_expected.to be_success }
      #
      #   # good
      #   it "responds with success" do
      #     expect(response).to be_successful
      #   end
      #
      #   it { is_expected.to be_successful }
      #
      class BeSuccessMatcher < RuboCop::Cop::Base
        extend RuboCop::Cop::AutoCorrector

        MESSAGE = 'Do not use deprecated `success?` method, use `successful?` instead.'

        def_node_search :expect_to_be_success?, <<~PATTERN
          (send (send nil? :expect (send nil? ...)) {:to :not_to :to_not} (send nil? :be_success))
        PATTERN

        def_node_search :is_expected_to_be_success?, <<~PATTERN
          (send (send nil? :is_expected) {:to :not_to :to_not} (send nil? :be_success))
        PATTERN

        def be_success_usage?(node)
          expect_to_be_success?(node) || is_expected_to_be_success?(node)
        end

        def on_send(node)
          return unless be_success_usage?(node)

          add_offense(node, message: MESSAGE) do |corrector|
            corrector.insert_after(node.loc.expression, 'ful')
          end
        end
      end
    end
  end
end
