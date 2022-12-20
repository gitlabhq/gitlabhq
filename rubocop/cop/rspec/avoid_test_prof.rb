# frozen_string_literal: true

require 'rubocop-rspec'

module RuboCop
  module Cop
    module RSpec
      # This cop checks for the usage of TestProf methods in migration specs.
      #
      # @example
      #
      #   # bad
      #   let_it_be(:user) { table(:users).create(username: 'test') }
      #   let_it_be_with_reload(:user) { table(:users).create(username: 'test') }
      #   let_it_be_with_refind(:user) { table(:users).create(username: 'test') }
      #
      #   before_all do
      #     do_something
      #   end
      #
      #   # good
      #   let(:user) { table(:users).create(username: 'test') }
      #   let!(:user) { table(:users).create(username: 'test') }
      #
      #   before(:all) do
      #     do_something
      #   end
      #
      #   before do
      #     do_something
      #   end
      class AvoidTestProf < RuboCop::Cop::Base
        MESSAGE = "Prefer %{alternatives} over `%{method}` in migration specs. " \
                  'See ' \
                  'https://docs.gitlab.com/ee/development/testing_guide/best_practices.html#testprof-in-migration-specs'

        LET_ALTERNATIVES = %w[`let` `let!`].freeze
        ALTERNATIVES = {
          let_it_be: LET_ALTERNATIVES,
          let_it_be_with_reload: LET_ALTERNATIVES,
          let_it_be_with_refind: LET_ALTERNATIVES,
          before_all: %w[`before` `before(:all)`]
        }.freeze

        FORBIDDEN_METHODS = ALTERNATIVES.keys.map(&:inspect).join(' ')
        RESTRICT_ON_SEND = ALTERNATIVES.keys

        def_node_matcher :forbidden_method_usage, <<~PATTERN
          (send nil? ${#{FORBIDDEN_METHODS}} ...)
        PATTERN

        def on_send(node)
          method = forbidden_method_usage(node)
          return unless method

          alternatives = ALTERNATIVES.fetch(method).join(' or ')

          add_offense(
            node,
            message: format(MESSAGE, method: method, alternatives: alternatives)
          )
        end
      end
    end
  end
end
