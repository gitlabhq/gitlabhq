# frozen_string_literal: true

module ActiveContext
  class Reference
    extend Concerns::ReferenceUtils
    extend Concerns::Preprocessor
    include Preprocessors::Chunking
    include Preprocessors::ContentFetcher
    include Preprocessors::Embeddings
    include Preprocessors::Preload

    DELIMITER = '|'

    class << self
      def deserialize(string)
        ref_klass(string)&.instantiate(string)
      end

      def instantiate(string)
        collection_id, routing, *args = deserialize_string(string)
        new(collection_id: collection_id, routing: routing, args: args)
      end

      def serialize(collection_id:, routing:, data:)
        args = serialize_data(data)
        new(collection_id: collection_id, routing: routing, args: args.values).serialize
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

    attr_reader :collection_id, :collection, :routing, :serialized_args, :ref_version
    attr_accessor :include_ref_fields
    attr_writer :documents

    def initialize(collection_id:, routing:, args: [])
      @collection_id = collection_id.to_i
      @collection = ActiveContext::CollectionCache.fetch(@collection_id)
      @routing = routing
      @serialized_args = Array(args)
      @ref_version = Time.now.to_i
      @include_ref_fields = @collection.respond_to?(:include_ref_fields) ? @collection.include_ref_fields : true
      init
    end

    def klass
      self.class.klass
    end

    def serialize
      self.class.join_delimited([collection_id, routing, *serialized_attributes].compact)
    end

    def init
      raise NotImplementedError
    end

    def serialized_attributes
      raise NotImplementedError
    end

    def documents
      @documents ||= []
    end

    def jsons
      docs = documents.empty? ? as_indexed_jsons : documents

      if respond_to?(:shared_attributes)
        base = shared_attributes
        docs = docs.map { |doc| base.merge(doc) }
      end

      docs.map.with_index do |json, index|
        result = json.merge(unique_identifier: unique_identifier(index))

        if include_ref_fields
          result.merge!(
            ref_id: identifier,
            ref_version: ref_version
          )
        end

        result
      end
    end

    def as_indexed_jsons
      return Array.wrap(as_indexed_json) if respond_to?(:as_indexed_json)

      raise NotImplementedError, "#{self.class} must implement either :as_indexed_json or :as_indexed_jsons"
    end

    def operation
      raise NotImplementedError
    end

    def identifier
      raise NotImplementedError
    end

    def unique_identifier(index)
      [unique_identifiers, index].flatten.join(':')
    end

    def unique_identifiers
      [identifier]
    end

    def embedding_versions
      collection_class&.current_indexing_embedding_versions || []
    end

    def collection_class
      collection.collection_class&.safe_constantize
    end

    def partition_name
      collection.name
    end

    def partition_number
      collection.partition_for(routing)
    end

    def partition
      "#{partition_name}#{ActiveContext.adapter.separator}#{partition_number}"
    end
  end
end
