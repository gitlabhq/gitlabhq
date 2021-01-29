# frozen_string_literal: true

# We're patching `ActiveSupport::Concern` in
# config/initializers/0_as_concern.rb
#
# We want to patch `ActiveSupport::Concern` for two reasons:
# 1. Allow defining class methods via: `class_methods` method
# 2. Allow `prepended do; end` work like `included do; end`
# If we don't need anything above, we don't need this patch nor the concern!

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
          klass_methods = const_get(:ClassMethods, false)
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

        class_methods_module = const_get(:ClassMethods, false)

        if instance_variable_defined?(:@_prepended_class_methods)
          class_methods_module.prepend @_prepended_class_methods
        end

        # Hack to resolve https://gitlab.com/gitlab-org/gitlab/-/issues/23932
        extend class_methods_module if ENV['STATIC_VERIFICATION']
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
