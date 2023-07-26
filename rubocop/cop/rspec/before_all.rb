# frozen_string_literal: true

require 'rubocop-rspec'

module Rubocop
  module Cop
    module RSpec
      # This cop checks for `before(:all) in RSpec tests`
      #
      # @example
      #
      #  bad
      #
      #  before(:all) do
      #    project.repository.add_tag(user, 'v1.2.3', 'master')
      #  end
      #
      #  good
      #
      #  before_all do
      #    project.repository.add_tag(user, 'v1.2.3', 'master')
      #  end
      #
      class BeforeAll < RuboCop::Cop::Base
        extend RuboCop::Cop::AutoCorrector

        MSG = "Prefer using `before_all` over `before(:all)`. See https://docs.gitlab.com/ee/development/testing_guide/best_practices.html#common-test-setup"

        RESTRICT_ON_SEND = %i[before].freeze

        def_node_matcher :before_all_block?, <<~PATTERN
          (send nil? :before (sym :all) ...)
        PATTERN

        def on_send(node)
          return unless before_all_block?(node)

          add_offense(node) do |corrector|
            replacement = 'before_all'
            corrector.replace(node.source_range, replacement)
          end
        end
      end
    end
  end
end
