module Gitlab
  module Utils
    module Override
      class Extension
        def self.verify_class!(klass, method_name)
          instance_method_defined?(klass, method_name) ||
            raise(
              NotImplementedError.new(
                "#{klass}\##{method_name} doesn't exist!"))
        end

        def self.instance_method_defined?(klass, name, include_super: true)
          klass.instance_methods(include_super).include?(name) ||
            klass.private_instance_methods(include_super).include?(name)
        end

        attr_reader :subject

        def initialize(subject)
          @subject = subject
        end

        def add_method_name(method_name)
          method_names << method_name
        end

        def add_class(klass)
          classes << klass
        end

        def verify!
          classes.each do |klass|
            index = klass.ancestors.index(subject)
            parents = klass.ancestors.drop(index + 1)

            method_names.each do |method_name|
              parents.any? do |parent|
                self.class.instance_method_defined?(
                  parent, method_name, include_super: false)
              end ||
                raise(
                  NotImplementedError.new(
                    "#{klass}\##{method_name} doesn't exist!"))
            end
          end
        end

        private

        def method_names
          @method_names ||= []
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
      # https://gitlab.com/gitlab-org/gitlab-ee/issues/1819
      def override(method_name)
        return unless ENV['STATIC_VERIFICATION']

        if is_a?(Class)
          Extension.verify_class!(self, method_name)
        else # We delay the check for modules
          Override.extensions[self] ||= Extension.new(self)
          Override.extensions[self].add_method_name(method_name)
        end
      end

      def included(base = nil)
        return super if base.nil? # Rails concern, ignoring it

        super

        if base.is_a?(Class) # We could check for Class in `override`
          # This could be `nil` if `override` was never called
          Override.extensions[self]&.add_class(base)
        end
      end

      alias_method :prepended, :included

      def self.extensions
        @extensions ||= {}
      end

      def self.verify!
        extensions.values.each(&:verify!)
      end
    end
  end
end
