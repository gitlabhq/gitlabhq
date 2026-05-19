# frozen_string_literal: true

module Gitlab
  module Ci
    # rubocop:disable CodeReuse/ActiveRecord -- we need to build a complicated query here
    class PipelineSourceHierarchy
      attr_reader :pipeline_id, :partition_id, :options

      def initialize(pipeline, options: {})
        @pipeline_id = pipeline.id
        @partition_id = pipeline.partition_id
        @options = options
      end

      def all_objects
        ancestors_cte = build_ancestors_cte
        descendants_cte = build_descendants_cte

        read_only(
          unscoped_model
            .with
            .recursive(ancestors_cte.to_arel, descendants_cte.to_arel)
            .from_union([cte_scope(ancestors_cte), cte_scope(descendants_cte)])
        )
      end

      def base_and_ancestors
        cte_relation(build_ancestors_cte)
      end

      def base_and_descendants
        cte_relation(build_descendants_cte)
      end

      private

      def cte_scope(cte)
        unscoped_model
          .from(cte.alias_to(source_table))
          .select(:pipeline_id, :partition_id)
      end

      def cte_relation(cte)
        read_only(
          unscoped_model
            .with
            .recursive(cte.to_arel)
            .from(cte.alias_to(source_table))
            .select(:pipeline_id, :partition_id)
        )
      end

      def unscoped_model
        ::Ci::Sources::Pipeline.unscoped
      end

      def source_table
        ::Ci::Sources::Pipeline.arel_table
      end

      # Seeds the CTE with a bare literal node rather than a table query,
      # ensuring the starting pipeline is always present even when it is the
      # root (i.e. it only appears as source_pipeline_id, never as pipeline_id).
      def node_seed_query
        unscoped_model
          .select(
            Arel.sql("#{pipeline_id}::bigint AS pipeline_id"),
            Arel.sql("#{partition_id}::bigint AS partition_id")
          )
          .from(Arel.sql('(SELECT 1) AS _seed'))
      end

      def build_ancestors_cte
        cte = ::Gitlab::SQL::RecursiveCTE.new(:ancestors)

        cte << node_seed_query

        cte << unscoped_model
          .select(
            source_table[:source_pipeline_id].as('pipeline_id'),
            source_table[:source_partition_id].as('partition_id')
          )
          .from([source_table, cte.table])
          .where(
            source_table[:pipeline_id].eq(cte.table[:pipeline_id])
              .and(source_table[:partition_id].eq(cte.table[:partition_id]))
              .and(project_condition)
          )

        cte
      end

      def build_descendants_cte
        cte = ::Gitlab::SQL::RecursiveCTE.new(:descendants)

        cte << node_seed_query

        cte << unscoped_model
          .select(source_table[:pipeline_id], source_table[:partition_id])
          .from([source_table, cte.table])
          .where(
            source_table[:source_pipeline_id].eq(cte.table[:pipeline_id])
              .and(source_table[:source_partition_id].eq(cte.table[:partition_id]))
              .and(project_condition)
          )

        cte
      end

      def project_condition
        case options[:project_condition]
        when :same      then source_table[:source_project_id].eq(source_table[:project_id])
        when :different then source_table[:source_project_id].not_eq(source_table[:project_id])
        else                 Arel.sql('TRUE')
        end
      end

      def read_only(relation)
        relation.extend(Gitlab::Database::ReadOnlyRelation)
        relation
      end
    end
    # rubocop:enable CodeReuse/ActiveRecord
  end
end
