# frozen_string_literal: true

module ActiveContext
  module Databases
    module Concerns
      module Executor
        attr_reader :adapter

        def initialize(adapter)
          @adapter = adapter
        end

        def create_collection(name, number_of_partitions:, options: {}, &block)
          builder = ActiveContext::Databases::CollectionBuilder.new
          yield(builder) if block

          full_name = adapter.full_collection_name(name)
          do_create_collection(
            name: full_name,
            number_of_partitions: number_of_partitions,
            fields: builder.fields,
            options: options
          )

          create_collection_record(full_name, number_of_partitions, options)
        end

        private

        def create_collection_record(name, number_of_partitions, options)
          collection = adapter.connection.collections.find_or_initialize_by(name: name)
          collection.update(
            number_of_partitions: number_of_partitions,
            include_ref_fields: options.fetch(:include_ref_fields, true)
          )
          collection.save!
        end

        def do_create_collection(...)
          raise NotImplementedError
        end
      end
    end
  end
end
