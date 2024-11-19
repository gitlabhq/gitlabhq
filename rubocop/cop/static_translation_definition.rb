# frozen_string_literal: true

module RuboCop
  module Cop
    # This cop flags translation definitions in static scopes because changing
    # locales has no effect and won't translate this text again.
    #
    # See https://docs.gitlab.com/ee/development/i18n/externalization.html#keep-translations-dynamic
    #
    # @example
    #
    # # bad
    # class MyExample
    #   # Constant
    #   Translation = _('A translation.')
    #
    #   # Class scope
    #   field :foo, title: _('A title')
    #
    #   validates :title, :presence, message: _('is missing')
    #
    #   # Memoized
    #   def self.translations
    #     @cached ||= { text: _('A translation.') }
    #   end
    #
    #   included do # or prepended or class_methods
    #     self.error_message = _('Something went wrong.')
    #   end
    # end
    #
    # # good
    # class MyExample
    #   # Keep translations dynamic.
    #   Translation = -> { _('A translation.') }
    #   # OR
    #   def translation
    #     _('A translation.')
    #   end
    #
    #   field :foo, title: -> { _('A title') }
    #
    #   validates :title, :presence, message: -> { _('is missing') }
    #
    #   def self.translations
    #     { text: _('A translation.') }
    #   end
    #
    #   included do # or prepended or class_methods
    #     self.error_message = -> { _('Something went wrong.') }
    #   end
    # end
    #
    class StaticTranslationDefinition < RuboCop::Cop::Base
      MSG = <<~TEXT.tr("\n", ' ')
        Translation is defined in static scope.
        Keep translations dynamic. See https://docs.gitlab.com/ee/development/i18n/externalization.html#keep-translations-dynamic
      TEXT

      RESTRICT_ON_SEND = %i[_ s_ n_].freeze

      # List of method names which are not considered real method definitions.
      # See https://api.rubyonrails.org/classes/ActiveSupport/Concern.html
      NON_METHOD_DEFINITIONS = %i[class_methods included prepended].to_set.freeze

      def_node_matcher :translation_method?, <<~PATTERN
        (send _ {#{RESTRICT_ON_SEND.map(&:inspect).join(' ')}} {dstr str}+)
      PATTERN

      def on_send(node)
        return unless translation_method?(node)

        static = true
        memoized = false

        node.each_ancestor do |ancestor|
          memoized = true if memoized?(ancestor)

          if dynamic?(ancestor, memoized)
            static = false
            break
          end
        end

        add_offense(node) if static
      end

      private

      def memoized?(node)
        node.type == :or_asgn
      end

      def dynamic?(node, memoized)
        lambda_or_proc?(node) ||
          named_block?(node) ||
          instance_method_definition?(node) ||
          unmemoized_class_method_definition?(node, memoized)
      end

      def lambda_or_proc?(node)
        node.lambda_or_proc?
      end

      def named_block?(node)
        return unless node.block_type?

        !NON_METHOD_DEFINITIONS.include?(node.method_name)
      end

      def instance_method_definition?(node)
        node.type == :def
      end

      def unmemoized_class_method_definition?(node, memoized)
        node.type == :defs && !memoized
      end
    end
  end
end
