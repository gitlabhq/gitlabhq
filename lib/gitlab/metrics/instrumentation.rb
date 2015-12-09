module Gitlab
  module Metrics
    # Module for instrumenting methods.
    #
    # This module allows instrumenting of methods without having to actually
    # alter the target code (e.g. by including modules).
    #
    # Example usage:
    #
    #     Gitlab::Metrics::Instrumentation.instrument_method(User, :by_login)
    module Instrumentation
      # Instruments a class method.
      #
      # mod  - The module to instrument as a Module/Class.
      # name - The name of the method to instrument.
      def self.instrument_method(mod, name)
        instrument(:class, mod, name)
      end

      # Instruments an instance method.
      #
      # mod  - The module to instrument as a Module/Class.
      # name - The name of the method to instrument.
      def self.instrument_instance_method(mod, name)
        instrument(:instance, mod, name)
      end

      def self.instrument(type, mod, name)
        return unless Metrics.enabled?

        alias_name = "_original_#{name}"
        target     = type == :instance ? mod : mod.singleton_class

        target.class_eval do
          alias_method(alias_name, name)

          define_method(name) do |*args, &block|
            ActiveSupport::Notifications.
              instrument("#{type}_method.method_call", module: mod, name: name) do
                __send__(alias_name, *args, &block)
              end
          end
        end
      end
    end
  end
end
