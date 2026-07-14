# frozen_string_literal: true

module Types
  module Analytics
    module Aggregation
      module BaseResponseType
        extend ActiveSupport::Concern

        class_methods do
          def declare_parameterized_field(part)
            adapter = ::Gitlab::Database::Aggregation::Graphql::Adapter
            params = part.respond_to?(:parameters) ? part.parameters : {}
            field part.identifier.to_sym,
              adapter.graphql_type(part.type),
              null: true,
              description: part.description do
              params.each do |param_name, param_config|
                gql_type = adapter.graphql_type(param_config[:type])
                gql_type = [gql_type] if param_config[:array]
                argument param_name, gql_type, required: false, description: param_config[:description]
              end
            end

            define_method(part.identifier) do |**field_kwargs|
              allowed_params = field_kwargs.slice(*params.keys)

              object[part.instance_key(parameters: allowed_params)]
            end
          end
        end
      end
    end
  end
end
