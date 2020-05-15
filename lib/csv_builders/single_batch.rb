# frozen_string_literal: true

module CsvBuilders
  class SingleBatch < CsvBuilder
    protected

    def each(&block)
      @collection.each(&block)
    end
  end
end
