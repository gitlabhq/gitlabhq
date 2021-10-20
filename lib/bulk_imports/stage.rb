# frozen_string_literal: true

module BulkImports
  class Stage
    def initialize(bulk_import)
      raise(ArgumentError, 'Expected an argument of type ::BulkImport') unless bulk_import.is_a?(::BulkImport)

      @bulk_import = bulk_import
    end

    def pipelines
      @pipelines ||= config
        .values
        .sort_by { |entry| entry[:stage] }
        .map do |entry|
          [entry[:stage], entry[:pipeline]]
        end
    end

    private

    def config
      # To be implemented in a sub-class
      NotImplementedError
    end
  end
end
