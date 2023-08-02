# frozen_string_literal: true

module CsvBuilder
  class SingleBatch < CsvBuilder::Builder
    protected

    def each(&block)
      @collection.each(&block)
    end
  end
end
