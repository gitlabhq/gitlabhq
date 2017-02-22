module RuboCop
  module Cop
    # This cop prevents usage of the `git` and `github` arguments to `gem` in a
    # `Gemfile` in order to avoid additional points of failure beyond
    # rubygems.org.
    class GemFetcher < RuboCop::Cop::Cop
      MSG = 'Do not use gems from git repositories, only use gems from RubyGems.'.freeze

      GIT_KEYS = [:git, :github].freeze

      def on_send(node)
        return unless gemfile?(node)

        func_name = node.children[1]
        return unless func_name == :gem

        node.children.last.each_node(:pair) do |pair|
          key_name = pair.children[0].children[0].to_sym
          if GIT_KEYS.include?(key_name)
            add_offense(node, pair.source_range, MSG)
          end
        end
      end

      private

      def gemfile?(node)
        node
          .location
          .expression
          .source_buffer
          .name
          .end_with?("Gemfile")
      end
    end
  end
end
