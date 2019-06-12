# frozen_string_literal: true

module QA
  module Runtime
    class Address
      attr_reader :address

      def initialize(instance, page)
        @instance = instance
        @address  = host + (page.is_a?(String) ? page : page&.path)
      end

      def host
        if @instance.is_a?(Symbol)
          Runtime::Scenario.send("#{@instance}_address")
        else
          @instance.to_s
        end
      end

      def self.valid?(value)
        uri = URI.parse(value)
        uri.is_a?(URI::HTTP) && !uri.host.nil?
      rescue URI::InvalidURIError
        false
      end
    end
  end
end
