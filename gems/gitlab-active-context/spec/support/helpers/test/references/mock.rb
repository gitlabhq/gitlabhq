# frozen_string_literal: true

module Test
  module References
    class Mock < ::ActiveContext::Reference
      def self.serialize_data(data)
        { identifier: data.id }
      end

      attr_reader :identifier

      def init
        @identifier, _ = serialized_args
      end

      def serialized_attributes
        [identifier]
      end

      def operation
        :upsert
      end

      def as_indexed_jsons
        [{ id: identifier }]
      end

      def partition_name
        'test'
      end

      def partition
        "#{partition_name}_0"
      end
    end
  end
end
