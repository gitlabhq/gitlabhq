# frozen_string_literal: true

module Ci
  class BuildSourceFinder
    def initialize(relation:, sources:, project:, params: {})
      raise ArgumentError, 'Only Ci::Builds are source searchable' unless relation.klass == Ci::Build

      @relation = relation
      @sources = sources
      @project = project
      @params = params
    end

    def execute
      return relation unless sources.present?

      filter_by_source
    end

    private

    attr_reader :relation, :sources, :project, :params

    # rubocop: disable CodeReuse/ActiveRecord -- Need specialized queries for database optimizations
    def filter_by_source
      relation
        .from("(#{build_source_scope.to_sql}) p_ci_build_sources, LATERAL (#{ci_builds_query.to_sql}) p_ci_builds")
    end

    def order
      Gitlab::Pagination::Keyset::Order.build(
        [
          Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
            attribute_name: 'build_id',
            order_expression: Ci::BuildSource.arel_table[:build_id].desc
          ),
          Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
            attribute_name: 'partition_id',
            order_expression: Ci::BuildSource.arel_table[:partition_id].desc
          )
        ])
    end

    def build_source_scope
      Gitlab::Pagination::Keyset::InOperatorOptimization::QueryBuilder.new(
        scope: scope,
        array_scope: array_scope,
        array_mapping_scope: array_mapping_scope
      ).execute
    end

    def ci_builds_query
      relation
        .where("id = p_ci_build_sources.build_id and partition_id = p_ci_build_sources.partition_id")
        .limit(1)
    end

    def scope
      Ci::BuildSource.where(project_id: project.id).order(order)
    end

    def array_scope
      Ci::BuildSource
        .where(project_id: project.id)
        .loose_index_scan(column: :source)
        .select(:source).where(source: sources)
    end

    def array_mapping_scope
      ->(source) { Ci::BuildSource.where(Ci::BuildSource.arel_table[:source].eq(source)) }
    end

    def get_source_ids_from_names(source_names)
      source_ids = []
      source_names.each do |source_name|
        source_ids << Ci::BuildSource.sources[source_name] if Ci::BuildSource.sources.key?(source_name)
      end

      source_ids
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end
