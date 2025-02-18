# frozen_string_literal: true

module ActiveContext
  module Databases
    module Concerns
      module Executor
        attr_reader :adapter

        def initialize(adapter)
          @adapter = adapter
        end

        def create_collection(name, number_of_partitions:, &block)
          builder = ActiveContext::Databases::CollectionBuilder.new
          yield(builder) if block

          full_name = adapter.full_collection_name(name)
          do_create_collection(
            name: full_name,
            number_of_partitions: number_of_partitions,
            fields: builder.fields
          )
        end

        private

        def do_create_collection(...)
          raise NotImplementedError
        end
      end
    end
  end
end
