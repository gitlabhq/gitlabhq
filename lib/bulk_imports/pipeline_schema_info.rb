# frozen_string_literal: true

module BulkImports
  class PipelineSchemaInfo
    def initialize(pipeline_class, portable_class)
      @pipeline_class = pipeline_class
      @portable_class = portable_class
    end

    def db_schema
      return unless relation
      return unless association

      Gitlab::Database::GitlabSchema.tables_to_schema[association.table_name]
    end

    def db_table
      return unless relation
      return unless association

      association.table_name
    end

    private

    attr_reader :pipeline_class, :portable_class

    def relation
      @relation ||= pipeline_class.try(:relation)
    end

    def association
      @association ||= portable_class.reflect_on_association(relation)
    end
  end
end
