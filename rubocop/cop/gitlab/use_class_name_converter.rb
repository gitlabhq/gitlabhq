# frozen_string_literal: true

module RuboCop
  module Cop
    module Gitlab
      # Checks for redundant use of `*.name.underscore.tr('/', '_')`
      #
      # @example
      #   # bad
      #   class Example
      #     def class_name
      #       self.name.underscore.tr('/', '_')
      #     end
      #   end
      #
      #   # good
      #   class Example
      #     def class_name
      #       ::Gitlab::Utils::ClassNameConverter.new(self).string_representation
      #     end
      #   end
      #
      class UseClassNameConverter < RuboCop::Cop::Base
        extend AutoCorrector

        MSG = 'Use `::Gitlab::Utils::ClassNameConverter.new(%<receiver>s).string_representation` ' \
          'instead of `%<original>s`.'

        RESTRICT_ON_SEND = %i[tr].freeze

        # @!method underscore_tr_pattern?(node)
        def_node_matcher :underscore_tr_pattern?, <<~PATTERN
          (send
            (send
              (send $_ :name)
              :underscore)
            :tr
            (str "/")
            (str "_"))
        PATTERN

        def on_send(node)
          check_node(node)
        end

        def on_csend(_node)
          # Intentionally empty - we don't want to check safe navigation calls
        end

        private

        def check_node(node)
          receiver = underscore_tr_pattern?(node)
          return unless receiver

          receiver_source = receiver.source
          original_source = node.source

          add_offense(
            node,
            message: format(MSG, receiver: receiver_source, original: original_source)
          ) do |corrector|
            replacement = "::Gitlab::Utils::ClassNameConverter.new(#{receiver_source}).string_representation"
            corrector.replace(node, replacement)
          end
        end
      end
    end
  end
end
