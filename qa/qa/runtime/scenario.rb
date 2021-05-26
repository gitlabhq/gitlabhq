# frozen_string_literal: true

require 'json'

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
            raise ArgumentError, "Empty `#{attribute}` attribute!" if value.to_s.empty?
          end
        end
      end

      def from_env(var)
        return if var.blank?

        JSON.parse(var).each { |k, v| define(k, v) }
      end

      def method_missing(name, *)
        raise ArgumentError, "Scenario attribute `#{name}` not defined!"
      end
    end
  end
end
