# frozen_string_literal: true

# rubocop:disable Gitlab/ModuleWithInstanceVariables
module Gitlab
  module Patch
    module Prependable
      class MultiplePrependedBlocks < StandardError
        def initialize
          super "Cannot define multiple 'prepended' blocks for a Concern"
        end
      end

      def prepend_features(base)
        return false if prepended?(base)

        super

        if const_defined?(:ClassMethods)
          klass_methods = const_get(:ClassMethods)
          base.singleton_class.prepend klass_methods
          base.instance_variable_set(:@_prepended_class_methods, klass_methods)
        end

        if instance_variable_defined?(:@_prepended_block)
          base.class_eval(&@_prepended_block)
        end

        true
      end

      def class_methods
        super

        if instance_variable_defined?(:@_prepended_class_methods)
          const_get(:ClassMethods).prepend @_prepended_class_methods
        end
      end

      def prepended(base = nil, &block)
        if base.nil?
          raise MultiplePrependedBlocks if
            instance_variable_defined?(:@_prepended_block)

          @_prepended_block = block
        else
          super
        end
      end

      def prepended?(base)
        index = base.ancestors.index(base)

        base.ancestors[0...index].index(self)
      end
    end
  end
end
