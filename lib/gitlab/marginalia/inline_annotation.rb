# frozen_string_literal: true

# Module with util methods to support ::Marginalia.without_annotation method.

module Gitlab
  module Marginalia
    module InlineAnnotation
      def without_annotation(&block)
        return unless block.present?

        annotation_stack.push(false)
        yield
      ensure
        annotation_stack.pop
      end

      def with_annotation(comment, &block)
        annotation_stack.push(true)
        super(comment, &block)
      ensure
        annotation_stack.pop
      end

      def annotation_stack
        Thread.current[:annotation_stack] ||= []
      end

      def annotation_stack_top
        annotation_stack.last
      end

      def annotation_allowed?
        annotation_stack.empty? ? true : annotation_stack_top
      end
    end
  end
end
