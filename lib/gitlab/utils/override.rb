# frozen_string_literal: true

require_dependency 'gitlab/utils'

module Gitlab
  module Utils
    module Override
      class Extension
        def self.verify_class!(klass, method_name, arity)
          extension = new(klass)
          parents = extension.parents_for(klass)
          extension.verify_method!(
            klass: klass, parents: parents, method_name: method_name, sub_method_arity: arity)
        end

        attr_reader :subject

        def initialize(subject)
          @subject = subject
        end

        def parents_for(klass)
          index = klass.ancestors.index(subject)
          klass.ancestors.drop(index + 1)
        end

        def verify!
          classes.each do |klass|
            parents = parents_for(klass)

            method_names.each_pair do |method_name, arity|
              verify_method!(
                klass: klass,
                parents: parents,
                method_name: method_name,
                sub_method_arity: arity)
            end
          end
        end

        def verify_method!(klass:, parents:, method_name:, sub_method_arity:)
          overridden_parent = parents.find do |parent|
            instance_method_defined?(parent, method_name)
          end

          raise NotImplementedError, "#{klass}\##{method_name} doesn't exist!" unless overridden_parent

          super_method_arity = find_direct_method(overridden_parent, method_name).arity

          unless arity_compatible?(sub_method_arity, super_method_arity)
            raise NotImplementedError, "#{subject}\##{method_name} has arity of #{sub_method_arity}, but #{overridden_parent}\##{method_name} has arity of #{super_method_arity}"
          end
        end

        def add_method_name(method_name, arity = nil)
          method_names[method_name] = arity
        end

        def add_class(klass)
          classes << klass
        end

        def verify_override?(method_name)
          method_names.has_key?(method_name)
        end

        private

        def instance_method_defined?(klass, name)
          klass.instance_methods(false).include?(name) ||
            klass.private_instance_methods(false).include?(name)
        end

        def find_direct_method(klass, name)
          method = klass.instance_method(name)
          method = method.super_method until method && klass == method.owner
          method
        end

        def arity_compatible?(sub_method_arity, super_method_arity)
          if sub_method_arity >= 0 && super_method_arity >= 0
            # Regular arguments
            sub_method_arity == super_method_arity
          else
            # It's too complex to check this case, just allow sub-method having negative arity
            # But we don't allow sub_method_arity > 0 yet super_method_arity < 0
            sub_method_arity < 0
          end
        end

        def method_names
          @method_names ||= {}
        end

        def classes
          @classes ||= []
        end
      end

      # Instead of writing patterns like this:
      #
      #     def f
      #       raise NotImplementedError unless defined?(super)
      #
      #       true
      #     end
      #
      # We could write it like:
      #
      #     extend ::Gitlab::Utils::Override
      #
      #     override :f
      #     def f
      #       true
      #     end
      #
      # This would make sure we're overriding something. See:
      # https://gitlab.com/gitlab-org/gitlab/issues/1819
      def override(method_name)
        return unless ENV['STATIC_VERIFICATION']

        Override.extensions[self] ||= Extension.new(self)
        Override.extensions[self].add_method_name(method_name)
      end

      def method_added(method_name)
        super

        return unless ENV['STATIC_VERIFICATION']
        return unless Override.extensions[self]&.verify_override?(method_name)

        method_arity = instance_method(method_name).arity
        if is_a?(Class)
          Extension.verify_class!(self, method_name, method_arity)
        else # We delay the check for modules
          Override.extensions[self].add_method_name(method_name, method_arity)
        end
      end

      def included(base = nil)
        super

        queue_verification(base) if base
      end

      def prepended(base = nil)
        super

        # prepend can override methods, thus we need to verify it like classes
        queue_verification(base, verify: true) if base
      end

      def extended(mod = nil)
        super

        # Hack to resolve https://gitlab.com/gitlab-org/gitlab/-/issues/23932
        is_not_concern_hack =
          (mod.is_a?(Class) || !name&.end_with?('::ClassMethods'))

        if mod && is_not_concern_hack
          queue_verification(mod.singleton_class)
        end
      end

      def queue_verification(base, verify: false)
        return unless ENV['STATIC_VERIFICATION']

        # We could check for Class in `override`
        # This could be `nil` if `override` was never called.
        # We also force verification for prepend because it can also override
        # a method like a class, but not the cases for include or extend.
        # This includes Rails helpers but not limited to.
        if base.is_a?(Class) || verify
          Override.extensions[self]&.add_class(base)
        end
      end

      def self.extensions
        @extensions ||= {}
      end

      def self.verify!
        extensions.each_value(&:verify!)
      end
    end
  end
end
