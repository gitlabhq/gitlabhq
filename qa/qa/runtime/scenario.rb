module QA
  module Runtime
    ##
    # Singleton approach to global test scenario arguments.
    #
    module Scenario
      extend self

      # TODO resolve that in CE
      attr_accessor :mattermost

      def define(args, &block)
        @arguments = args
        instance_exec(&block)
      end

      def method_missing(name, *)
        raise ArgumentError, "Scenario attribute `#{name}` not defined!"
      end

      private

      def attributes(*accessors)
        accessors.each_with_index do |accessor, index|
          define_singleton_method(accessor) do
            @arguments[index].tap do |value|
              if value.to_s.empty?
                raise ArgumentError, "Empty `#{accessor}` attribute!"
              end
            end
          end
        end
      end
    end
  end
end
