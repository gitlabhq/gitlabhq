module QA
  module Runtime
    ##
    # Singleton approach to global test scenario arguments.
    #
    module Scenario
      extend self

      def attributes
        @attributes ||= {}
      end

      def define(attribute, value)
        attributes.store(attribute.to_sym, value)

        define_singleton_method(attribute) do
          attributes[attribute.to_sym].tap do |value|
            if value.to_s.empty?
              raise ArgumentError, "Empty `#{attribute}` attribute!"
            end
          end
        end
      end

      def method_missing(name, *)
        raise ArgumentError, "Scenario attribute `#{name}` not defined!"
      end
    end
  end
end
