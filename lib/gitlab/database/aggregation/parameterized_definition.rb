# frozen_string_literal: true

module Gitlab
  module Database
    module Aggregation
      module ParameterizedDefinition
        extend ActiveSupport::Concern

        attr_reader :parameters

        def initialize(*args, parameters: {}, **kwargs)
          super

          @parameters = parameters || {}
        end

        def instance_key(configuration)
          return super unless parameterized? && configuration[:parameters].present?

          parameters_postfix = parameters.keys.map do |p_key|
            val = instance_parameter(p_key, configuration) || ''
            val.is_a?(Array) ? val.join('_') : val
          end.join('_')

          unless /\A\w+\z/.match?(parameters_postfix)
            parameters_postfix = OpenSSL::Digest::SHA256.hexdigest(parameters_postfix)[0...5]
          end

          "#{super}_#{parameters_postfix}"
        end

        def validate_part(part)
          super
          validate_parameters(part)
        end

        private

        def instance_parameter(param_identifier, configuration)
          return unless parameters[param_identifier]

          val = configuration.dig(:parameters, param_identifier)
          return unless val

          parameters.dig(param_identifier, :array) ? Array.wrap(val) : val
        end

        def parameterized?
          parameters.present?
        end

        def validate_parameters(part)
          parameters.each do |param_key, param_opts|
            allowed = param_opts[:in]
            next unless allowed

            val = instance_parameter(param_key, part.configuration)
            next unless val

            invalid = Array.wrap(val).reject { |v| v.in?(allowed) }
            next if invalid.empty?

            part.errors.add(param_key,
              format(s_("AggregationEngine|Invalid value(s) for parameter `%{param}`: %{values}"),
                param: param_key,
                values: invalid.join(', ')))
          end
        end
      end
    end
  end
end
