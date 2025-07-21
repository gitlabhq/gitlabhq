# frozen_string_literal: true

require 'rubocop-rspec'

module RuboCop
  module Cop
    module RSpec
      # Forbids `before(:all)` in **regular** RSpec example groups and
      # autocorrects it to `before_all`, the TestProf helper that wraps the group
      # in a single DB transaction.  See:
      # https://docs.gitlab.com/ee/development/testing_guide/best_practices.html#common-test-setup
      #
      # **Exception: migration specs**
      # Specs living under `spec/migrations/` (or tagged `:migration`)
      # cannot run inside a transaction, so TestProf helpers are disabled.
      # In those files you should keep using plain `before(:all)` (or `before`)
      # as documented here:
      # https://docs.gitlab.com/ee/development/testing_guide/best_practices.html#testprof-in-migration-specs
      #
      # @example
      #
      #   # bad
      #   before(:all) { project.add_tag(user, 'v1.2.3', 'main') }
      #
      #   # good
      #   before_all   { project.add_tag(user, 'v1.2.3', 'main') }
      #
      #   # good (migration spec)
      #   before(:all) { add_column(:foo, :bar, :string) }
      class BeforeAll < RuboCop::Cop::Base
        extend RuboCop::Cop::AutoCorrector

        MSG = "Prefer using `before_all` over `before(:all)`. See https://docs.gitlab.com/ee/development/testing_guide/best_practices.html#common-test-setup"

        RESTRICT_ON_SEND = %i[before].freeze

        # @!method before_all_block?(node)
        def_node_matcher :before_all_block?, <<~PATTERN
          (send nil? :before (sym :all) ...)
        PATTERN

        def on_send(node)
          return unless before_all_block?(node)

          add_offense(node) do |corrector|
            replacement = 'before_all'
            corrector.replace(node, replacement)
          end
        end
      end
    end
  end
end
