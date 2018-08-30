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

      module MetaConcern
        def extended(base)
          super
          base.instance_variable_set(:@_prepend_dependencies, [])
        end
      end

      def self.prepended(base)
        super
        base.singleton_class.prepend MetaConcern
      end

      def append_features(base)
        super

        prepend_features(base)
      end

      def prepend_features(base)
        if base.instance_variable_defined?(:@_prepend_dependencies)
          base.instance_variable_get(:@_prepend_dependencies) << self
          false
        else
          return false if prepended?(base)

          @_prepend_dependencies.each { |dep| base.prepend(dep) }

          super

          if const_defined?(:ClassMethods)
            base.singleton_class.prepend const_get(:ClassMethods)
          end

          if instance_variable_defined?(:@_prepended_block)
            base.class_eval(&@_prepended_block)
          end
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

        @_prepend_dependencies.index(self) ||
          base.ancestors[0...index].index(self)
      end
    end
  end
end
