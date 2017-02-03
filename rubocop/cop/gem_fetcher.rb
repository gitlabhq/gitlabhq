module RuboCop
  module Cop
    # Cop that checks for all gems specified in the Gemfile, and will
    # alert if any gem is to be fetched not from the RubyGems index.
    # This enforcement is done so as to minimize external build
    # dependencies and build times.
    class GemFetcher < RuboCop::Cop::Cop
      MSG = 'Do not use gems from git repositories, only use gems from RubyGems.'

      GIT_KEYS = [:git, :github]

      def on_send(node)
        file_path = node.location.expression.source_buffer.name
        return unless file_path.end_with?("Gemfile")

        func_name = node.children[1]
        return unless func_name == :gem

        node.children.last.each_node(:pair) do |pair|
          key_name = pair.children[0].children[0].to_sym
          if GIT_KEYS.include?(key_name)
            add_offense(node, :selector)
          end
        end
      end
    end
  end
end
