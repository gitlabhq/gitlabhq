# frozen_string_literal: true

module Types
  module Analytics
    module Aggregation
      module EngineResponseDimensionsType
        class << self
          def build(engine, graphql_context)
            adapter = ::Gitlab::Database::Aggregation::Graphql::Adapter
            types_prefix = adapter.types_prefix(graphql_context[:types_prefix])

            Class.new(BaseObject) do
              include BaseResponseType
              graphql_name "#{types_prefix}AggregationResponseDimensions"
              description "Response dimensions for #{types_prefix} aggregation engine"

              def self.declare_association_field(dimension)
                name = dimension.identifier.to_s.delete_suffix('_id')
                model = dimension.association[:model] || name.camelize.constantize
                type = dimension.association[:graphql_type] || "::Types::#{model.name}Type".constantize

                field name.to_sym,
                  type,
                  null: true,
                  description: dimension.description

                define_method(name) do
                  association_id = object[dimension.instance_key({})]
                  BatchLoader::GraphQL.for(association_id).batch do |ids, loader, _args|
                    objects = model.id_in(ids).index_by(&:id)

                    ids.each { |id| loader.call(id, objects[id]) }
                  end
                end
              end

              associations = engine.dimensions.select(&:association?)

              associations.each { |dimension| declare_association_field(dimension) }
              (engine.dimensions - associations).each { |dimension| declare_parameterized_field(dimension) }
            end
          end
        end
      end
    end
  end
end
