# frozen_string_literal: true

module Gitlab
  module Database
    module Aggregation
      module ParameterizedDefinition
        extend ActiveSupport::Concern

        included do
          class << self
            attr_accessor :supported_parameters
          end
        end

        attr_reader :parameters

        def initialize(*args, parameters: {}, **kwargs)
          super

          guard_parameters_definition!(parameters)

          @parameters = parameters || {}
        end

        def to_hash
          super.merge(parameters: parameters)
        end

        def instance_key(configuration)
          return super unless parameterized? && configuration[:parameters].present?

          parameters_postfix = parameters.keys.map { |p_key| instance_parameter(p_key, configuration) || '' }.join('_')

          unless /\A\w+\z/.match?(parameters_postfix)
            parameters_postfix = OpenSSL::Digest::SHA256.hexdigest(parameters_postfix)[0...5]
          end

          "#{identifier}_#{parameters_postfix}"
        end

        private

        def instance_parameter(param_identifier, configuration)
          configuration.dig(:parameters, param_identifier)
        end

        def parameterized?
          parameters.present?
        end

        def guard_parameters_definition!(params)
          params.each_key do |identifier|
            unless identifier.in?(self.class.supported_parameters || [])
              raise "Parameter `#{identifier}` is not in supported parameters: #{self.class.supported_parameters}"
            end
          end
        end
      end
    end
  end
end
