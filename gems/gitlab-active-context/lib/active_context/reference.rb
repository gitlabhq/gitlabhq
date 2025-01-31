# frozen_string_literal: true

module ActiveContext
  class Reference
    extend Concerns::ReferenceUtils

    DELIMITER = '|'
    PRELOAD_BATCH_SIZE = 1_000

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

      def preload(refs)
        refs.group_by(&:class).each do |klass, class_refs|
          class_refs.each_slice(PRELOAD_BATCH_SIZE) do |group_slice|
            klass.preload_refs(group_slice)
          end
        end

        refs
      end

      def serialize
        raise NotImplementedError
      end

      def preload_refs(refs)
        refs
      end

      def klass
        name.demodulize
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
