module RuboCop
  module Cop
    # This cop makes sure that custom error classes, when empty, are declared
    # with Class.new.
    #
    # @example
    #   # bad
    #   class FooError < StandardError
    #   end
    #
    #   # okish
    #   class FooError < StandardError; end
    #
    #   # good
    #   FooError = Class.new(StandardError)
    class CustomErrorClass < RuboCop::Cop::Cop
      MSG = 'Use `Class.new(SuperClass)` to define an empty custom error class.'.freeze

      def on_class(node)
        _klass, parent, body = node.children

        return if body

        parent_klass = class_name_from_node(parent)

        return unless parent_klass && parent_klass.to_s.end_with?('Error')

        add_offense(node, :expression)
      end

      def autocorrect(node)
        klass, parent, _body = node.children
        replacement = "#{class_name_from_node(klass)} = Class.new(#{class_name_from_node(parent)})"

        lambda do |corrector|
          corrector.replace(node.source_range, replacement)
        end
      end

      private

      # The nested constant `Foo::Bar::Baz` looks like:
      #
      #   s(:const,
      #     s(:const,
      #       s(:const, nil, :Foo), :Bar), :Baz)
      #
      # So recurse through that to get the name as written in the source.
      #
      def class_name_from_node(node, suffix = nil)
        return unless node&.type == :const

        name = node.children[1].to_s
        name = "#{name}::#{suffix}" if suffix

        if node.children[0]
          class_name_from_node(node.children[0], name)
        else
          name
        end
      end
    end
  end
end
