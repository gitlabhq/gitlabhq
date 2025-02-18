# frozen_string_literal: true

module ActiveContext
  class Reference
    extend Concerns::ReferenceUtils
    extend Concerns::Preprocessor

    DELIMITER = '|'

    class << self
      def deserialize(string)
        ref_klass = ref_klass(string)

        if ref_klass
          ref_klass.instantiate(string)
        else
          Search::Elastic::Reference.deserialize(string)
        end
      end

      def instantiate(string)
        new(*deserialize_string(string))
      end

      def serialize
        raise NotImplementedError
      end

      def klass
        name.demodulize
      end

      def preprocess_references(refs)
        preprocess(refs)
      end
    end

    def klass
      self.class.klass
    end

    def serialize
      raise NotImplementedError
    end

    def as_indexed_json
      raise NotImplementedError
    end

    def operation
      raise NotImplementedError
    end

    def partition_name
      raise NotImplementedError
    end

    def identifier
      raise NotImplementedError
    end

    def routing
      nil
    end
  end
end
