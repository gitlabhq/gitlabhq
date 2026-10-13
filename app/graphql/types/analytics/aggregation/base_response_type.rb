# frozen_string_literal: true

module Types
  module Analytics
    module Aggregation
      module BaseResponseType
        extend ActiveSupport::Concern

        class_methods do
          def declare_parameterized_field(part, field_name: part.identifier.to_sym)
            adapter = ::Gitlab::Database::Aggregation::Graphql::Adapter
            params = part.respond_to?(:parameters) ? part.parameters : {}
            field field_name, adapter.graphql_type(part.type), null: true,
              description: part.description do |field_definition|
              declare_parameter_arguments(field_definition, params)
            end

            define_method(field_name) do |**field_kwargs|
              allowed_params = field_kwargs.slice(*params.keys)

              object[part.instance_key(parameters: allowed_params)]
            end
          end

          def declare_association_field(dimension)
            name = dimension.identifier.to_s.delete_suffix('_id')
            model = dimension.association[:model] || name.camelize.constantize
            type = dimension.association[:graphql_type] || "::Types::#{model.name}Type".constantize
            custom_finder = dimension.association[:finder]
            preloader = dimension.association[:preloader]
            params = dimension.respond_to?(:parameters) ? dimension.parameters : {}

            field name.to_sym, type, null: true, description: dimension.description do |field_definition|
              declare_parameter_arguments(field_definition, params)
            end

            define_method(name) do |**field_kwargs|
              association_id = object[dimension.instance_key(parameters: field_kwargs.slice(*params.keys))]
              return if association_id.nil?

              # `key` keeps each dimension in its own batch: the batch is keyed on the block source
              # location, and every association field is defined here. The user travels in the key
              # too, so the block does not close over instance state.
              BatchLoader::GraphQL.for(association_id).batch(key: [dimension, current_user]) do |ids, loader, args|
                objects = if custom_finder
                            custom_finder.call(ids)
                          else
                            model.id_in(ids).index_by(&:id)
                          end

                if preloader
                  _batch_dimension, batch_user = args[:key]
                  preloader.new(objects.values, batch_user).execute
                end

                ids.each { |id| loader.call(id, objects[id]) }
              end
            end
          end

          private

          def declare_parameter_arguments(field_definition, params)
            adapter = ::Gitlab::Database::Aggregation::Graphql::Adapter

            params.each do |param_name, param_config|
              gql_type = adapter.graphql_type(param_config[:type])
              gql_type = [gql_type] if param_config[:array]
              field_definition.argument param_name, gql_type, required: false, description: param_config[:description]
            end
          end
        end
      end
    end
  end
end
