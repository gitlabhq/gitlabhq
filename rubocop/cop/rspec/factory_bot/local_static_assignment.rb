# frozen_string_literal: true

require 'rubocop-rspec'

module RuboCop
  module Cop
    module RSpec
      module FactoryBot
        # Flags local assignments during factory "load time". This leads to
        # static data definitions.
        #
        # Move these definitions into attribute block or
        # `transient` block to ensure that the data is evaluated during
        # "runtime" and remains dynamic.
        #
        # @example
        #   # bad
        #   factory :foo do
        #     random = rand(23)
        #     baz { "baz-#{random}" }
        #
        #     trait :a_trait do
        #       random = rand(23)
        #       baz { "baz-#{random}" }
        #     end
        #
        #     transient do
        #       random = rand(23)
        #       baz { "baz-#{random}" }
        #     end
        #   end
        #
        #   # good
        #   factory :foo do
        #     baz { "baz-#{random}" }
        #
        #     trait :a_trait do
        #       baz { "baz-#{random}" }
        #     end
        #
        #     transient do
        #       random { rand(23) }
        #     end
        #   end
        class LocalStaticAssignment < RuboCop::Cop::Base
          MSG = 'Avoid local static assignemnts in factories which lead to static data definitions.'

          RESTRICT_ON_SEND = %i[factory transient trait].freeze

          def_node_search :local_assignment, <<~PATTERN
            (begin $(lvasgn ...))
          PATTERN

          def on_send(node)
            return unless node.parent&.block_type?

            node.parent.each_child_node(:begin) do |begin_node|
              begin_node.each_child_node(:lvasgn) do |lvasgn_node|
                add_offense(lvasgn_node)
              end
            end
          end
        end
      end
    end
  end
end
