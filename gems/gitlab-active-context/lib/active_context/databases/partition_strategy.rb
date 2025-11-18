# frozen_string_literal: true

module ActiveContext
  module Databases
    class PartitionStrategy
      def initialize(name:, number_of_partitions:)
        @name = name
        @number_of_partitions = number_of_partitions
      end

      def partition_names
        Array.new(@number_of_partitions) do |i|
          generate_partition_name(i)
        end
      end

      def collection_name
        @name
      end

      def generate_partition_name(index)
        "#{@name}#{ActiveContext.adapter.separator}#{index}"
      end

      def fully_exists?(&partition_exists_check)
        partition_names.all?(&partition_exists_check)
      end

      def each_partition
        partition_names.each do |name|
          yield name
        end
      end
    end
  end
end
