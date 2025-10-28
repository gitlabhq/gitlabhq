# frozen_string_literal: true

module ActiveContext
  module Databases
    module Concerns
      module ElasticExecutor
        include Executor

        private

        def raw_client
          @raw_client ||= adapter.client.client
        end

        def do_create_collection(name:, number_of_partitions:, fields:, options: {})
          strategy = PartitionStrategy.new(
            name: name,
            number_of_partitions: number_of_partitions
          )

          return if collection_exists?(strategy)

          strategy.each_partition do |partition_name|
            create_partition(partition_name, fields, options) unless index_exists?(partition_name)
          end

          create_alias(strategy) unless alias_exists?(strategy.collection_name)
        end

        def create_partition(name, fields, options = {})
          body = {
            mappings: {
              dynamic: 'strict',
              properties: mappings(fields, options)
            },
            settings: settings(fields)
          }

          raw_client.indices.create(index: name, body: body)
        end

        def create_alias(strategy)
          actions = [{
            add: {
              indices: strategy.partition_names,
              alias: strategy.collection_name
            }
          }]
          raw_client.indices.update_aliases(body: { actions: actions })
        end

        def mappings(fields, options = {})
          field_mappings = build_field_mappings(fields)

          if options.fetch(:include_ref_fields, true)
            field_mappings.merge!(
              ref_id: { type: 'keyword' },
              ref_version: { type: 'long' }
            )
          end

          field_mappings
        end

        def build_field_mappings(fields)
          fields.each_with_object({}) do |field, mappings|
            mappings[field.name] = case field
                                   when Field::Bigint
                                     { type: 'long' }
                                   when Field::Integer
                                     { type: 'integer' }
                                   when Field::Smallint
                                     { type: 'short' }
                                   when Field::Boolean
                                     { type: 'boolean' }
                                   when Field::Keyword
                                     { type: 'keyword' }
                                   when Field::Text
                                     { type: 'text' }
                                   when Field::Vector
                                     vector_field_mapping(field)
                                   else
                                     raise ArgumentError, "Unknown field type: #{field.class}"
                                   end
          end
        end

        def collection_exists?(strategy)
          return false unless alias_exists?(strategy.collection_name)

          strategy.fully_exists? do |partition_name|
            index_exists?(partition_name)
          end
        end

        def index_exists?(name)
          raw_client.indices.exists?(index: name)
        end

        def alias_exists?(name)
          raw_client.indices.exists_alias?(name: name)
        end

        def settings(_)
          {}
        end
      end
    end
  end
end
