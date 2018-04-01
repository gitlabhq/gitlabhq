module Gitlab
  module Ci
    class Trace
      module ChunkedFile
        module Concerns
          module Hooks
            extend ActiveSupport::Concern

            included do
              class_attribute :_before_methods, :_after_methods,
                :instance_writer => false
              self._before_methods = Hash.new []
              self._after_methods = Hash.new []
            end

            class_methods do
              def before_method(kind, callback)
                self._before_methods = self._before_methods.
                  merge kind => _before_methods[kind] + [callback]
              end

              def after_method(kind, callback)
                self._after_methods = self._after_methods.
                  merge kind => _after_methods[kind] + [callback]
              end
            end

            def method_added(method_name)
              return if self.class._before_methods.values.include?(method_name)
              return if self.class._after_methods.values.include?(method_name)
              return if hooked_methods.include?(method_name)

              add_hooks_to(method_name)
            end

            private

            def hooked_methods
              @hooked_methods ||= []
            end

            def add_hooks_to(method_name)
              hooked_methods << method_name

              original_method = instance_method(method_name)

              # re-define the method, but notice how we reference the original
              # method definition
              define_method(method_name) do |*args, &block|
                self.class._before_methods[method_name].each { |hook| method(hook).call }

                # now invoke the original method
                original_method.bind(self).call(*args, &block).tap do
                  self.class._after_methods[method_name].each { |hook| method(hook).call }
                end
              end
            end
          end
        end
      end
    end
  end
end
