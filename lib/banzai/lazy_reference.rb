module Banzai
  class LazyReference
    def self.load(refs)
      lazy_references, values = refs.partition { |ref| ref.is_a?(self) }

      lazy_values = lazy_references.group_by(&:klass).flat_map do |klass, refs|
        ids = refs.flat_map(&:ids)
        klass.where(id: ids)
      end

      values + lazy_values
    end

    attr_reader :klass, :ids

    def initialize(klass, ids)
      @klass = klass
      @ids = Array.wrap(ids).map(&:to_i)
    end

    def load
      self.klass.where(id: self.ids)
    end
  end
end
