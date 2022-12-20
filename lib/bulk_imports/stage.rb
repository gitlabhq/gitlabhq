# frozen_string_literal: true

module BulkImports
  class Stage
    def initialize(bulk_import_entity)
      unless bulk_import_entity.is_a?(::BulkImports::Entity)
        raise(ArgumentError, 'Expected an argument of type ::BulkImports::Entity')
      end

      @bulk_import_entity = bulk_import_entity
      @bulk_import = bulk_import_entity.bulk_import
    end

    def pipelines
      @pipelines ||= config
        .values
        .sort_by { |entry| entry[:stage] }
    end

    private

    attr_reader :bulk_import, :bulk_import_entity

    def config
      # To be implemented in a sub-class
      NotImplementedError
    end
  end
end
