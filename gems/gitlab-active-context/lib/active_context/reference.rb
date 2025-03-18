# frozen_string_literal: true

module ActiveContext
  class Reference
    extend Concerns::ReferenceUtils
    extend Concerns::Preprocessor

    DELIMITER = '|'

    class << self
      def deserialize(string)
        ref_klass(string)&.instantiate(string)
      end

      def instantiate(string)
        new(*deserialize_string(string))
      end

      def serialize(collection_id, routing, data)
        new(collection_id, routing, *serialize_data(data)).serialize
      end

      def serialize_data
        raise NotImplementedError
      end

      def klass
        name.demodulize
      end

      def preprocess_references(refs)
        preprocess(refs)
      end
    end

    attr_reader :collection_id, :collection, :routing, :serialized_args

    def initialize(collection_id, routing, *serialized_args)
      @collection_id = collection_id.to_i
      @collection = ActiveContext::CollectionCache.fetch(@collection_id)
      @routing = routing
      @serialized_args = serialized_args
      init
    end

    def klass
      self.class.klass
    end

    def serialize
      self.class.join_delimited([collection_id, routing, serialize_arguments].flatten.compact)
    end

    def init
      raise NotImplementedError
    end

    def serialize_arguments
      raise NotImplementedError
    end

    def as_indexed_json
      raise NotImplementedError
    end

    def operation
      raise NotImplementedError
    end

    def identifier
      raise NotImplementedError
    end

    def partition_name
      collection.name
    end

    def partition_number
      collection.partition_for(routing)
    end
  end
end
