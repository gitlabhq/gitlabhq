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
      SERIES = 'method_calls'

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

        if type == :instance
          target = mod
          label  = "#{mod.name}##{name}"
        else
          target = mod.singleton_class
          label  = "#{mod.name}.#{name}"
        end

        target.class_eval <<-EOF, __FILE__, __LINE__ + 1
          alias_method :#{alias_name}, :#{name}

          def #{name}(*args, &block)
            trans = Gitlab::Metrics::Instrumentation.transaction

            if trans
              start    = Time.now
              retval   = #{alias_name}(*args, &block)
              duration = (Time.now - start) * 1000.0

              trans.add_metric(Gitlab::Metrics::Instrumentation::SERIES,
                               { duration: duration },
                               method: #{label.inspect})

              retval
            else
              #{alias_name}(*args, &block)
            end
          end
        EOF
      end

      # Small layer of indirection to make it easier to stub out the current
      # transaction.
      def self.transaction
        Transaction.current
      end
    end
  end
end
