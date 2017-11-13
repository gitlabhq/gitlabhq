# frozen_string_literal: true

require 'rubocop-rspec'

module RuboCop
  module Cop
    module RSpec
      # Checks for verbose include metadata used in the specs.
      #
      # @example
      #   # bad
      #   describe MyClass, js: true do
      #   end
      #
      #   # good
      #   describe MyClass, :js do
      #   end
      class VerboseIncludeMetadata < Cop
        MSG = 'Use `%s` instead of `%s`.'

        SELECTORS = %i[describe context feature example_group it specify example scenario its].freeze

        def_node_matcher :include_metadata, <<-PATTERN
          (send {(const nil :RSpec) nil} {#{SELECTORS.map(&:inspect).join(' ')}}
            !const
            ...
            (hash $...))
        PATTERN

        def_node_matcher :invalid_metadata?, <<-PATTERN
          (pair
            (sym $...)
            (true))
        PATTERN

        def on_send(node)
          invalid_metadata_matches(node) do |match|
            add_offense(node, :expression, format(MSG, good(match), bad(match)))
          end
        end

        def autocorrect(node)
          lambda do |corrector|
            invalid_metadata_matches(node) do |match|
              corrector.replace(match.loc.expression, good(match))
            end
          end
        end

        private

        def invalid_metadata_matches(node)
          include_metadata(node) do |matches|
            matches.select(&method(:invalid_metadata?)).each do |match|
              yield match
            end
          end
        end

        def bad(match)
          "#{metadata_key(match)}: true"
        end

        def good(match)
          ":#{metadata_key(match)}"
        end

        def metadata_key(match)
          match.children[0].source
        end
      end
    end
  end
end
