# frozen_string_literal: true

require 'rubocop/cop/rspec/base'

module RuboCop
  module Cop
    module RSpec
      # Flags redundant use of `type` RSpec metatag if it can be inferred by spec location.
      #
      # @example
      #   # bad
      #   # in spec/models/foo_spec.rb
      #   RSpec.describe Foo, type: :model
      #
      #   # good
      #   # in spec/models/foo_spec.rb
      #   RSpec.describe Foo # inferred by spec location
      #
      #   # also good
      #   # in spec/lib/foo_spec.rb
      #   RSpec.describe Foo, type: :model # explicitly overridden
      class RedundantMetatagType < RuboCop::Cop::RSpec::Base
        include RuboCop::Cop::RSpec::TopLevelGroup
        include RuboCop::Cop::RangeHelp
        extend RuboCop::Cop::AutoCorrector

        MSG = "Redundant RSpec metatag `type: :%{value}` can be removed since it's inferred by spec location."

        # @!method type_value(node)
        def_node_matcher :type_value, <<~PATTERN
          (block
            (send #rspec? {#ExampleGroups.all #Examples.all} ...
              (hash <$(pair (sym :type) (sym $_)) ...>)
            )
            ...
          )
        PATTERN

        # For example:
        #  - `RSpec.describe ... do`
        #  - `context ... do`
        def on_block(node)
          check_redundant_type(node)
        end

        # For example:
        #  - `RSpec.describe ... do |param|`
        #  - `context ... do |param|`
        alias_method :on_numblock, :on_block

        private

        def check_redundant_type(node)
          type_value(node) do |type_pair_node, value|
            next unless value.to_s == type_by_location

            message = format(MSG, value: value)

            add_offense(type_pair_node, message: message) do |corrector|
              remove_pair(corrector, type_pair_node)
            end
          end
        end

        def remove_pair(corrector, node)
          corrector.remove(
            range_with_surrounding_comma(
              range_with_surrounding_space(
                node.source_range,
                side: :left
              ),
              :left
            )
          )
        end

        def type_by_location
          return @type_by_location if defined?(@type_by_location)

          # See spec/support/rspec.rb
          @type_by_location = %r{/spec/([^/]+)/}
            .match(processed_source.file_path)
            &.match(1)
            &.singularize
        end
      end
    end
  end
end
