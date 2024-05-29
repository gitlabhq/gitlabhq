# frozen_string_literal: true

# rubocop:disable CodeReuse/ActiveRecord -- This module is generating ActiveRecord relations therefore using AR methods is necessary
module UnnestedInFilters
  class Rewriter
    include Gitlab::Utils::StrongMemoize

    class ValueTable
      def initialize(model, attribute, values)
        @model = model
        @attribute = attribute.to_s
        @values = values
      end

      def to_sql
        "#{serialized_values} AS #{table_name}(#{column_name})"
      end

      def as_predicate
        "#{model.table_name}.#{column_name} = #{table_name}.#{column_name}"
      end

      private

      attr_reader :model, :attribute, :values

      delegate :connection, :columns, :attribute_types, to: :model, private: true
      delegate :quote, :quote_table_name, :quote_column_name, :visitor, to: :connection

      def table_name
        quote_table_name(attribute.pluralize)
      end

      def column_name
        quote_column_name(attribute)
      end

      def serialized_values
        if values.is_a?(Arel::Nodes::SelectStatement)
          "(#{serialized_arel_value})"
        else
          "unnest(#{serialized_array_values}::#{sql_type}[])"
        end
      end

      def serialized_arel_value
        visitor.compile(values, unprepared_statement_collector)
      end

      def serialized_array_values
        values.map(&:value)
              .then { |value| array_type.serialize(value) }
              .then { |array| quote(array) }
      end

      def array_type
        ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Array.new(attribute_types[attribute])
      end

      def sql_type
        column.sql_type_metadata.sql_type
      end

      def column
        columns.find { |column| column.name == attribute }
      end

      def unprepared_statement_collector
        Arel::Collectors::SubstituteBinds.new(
          connection,
          Arel::Collectors::SQLString.new
        )
      end
    end

    # A naive query planner implementation.
    # Checks if a database-level index can be utilized by given filtering and ordering predicates.
    #
    # Supported index conditions:
    #     - All columns queried are present in the index or partial predicate
    #     - Unqueried index columns are at the end of the index
    #     - Partial indices if the partial index predicate contains only one column.
    #     - Only the `=` operator present in partial index predicate.
    #
    # Examples:
    #
    # ------------------------------------------------------------------------------
    # Queried             | Index                                      | Supported?
    # (col_1, col_2)      | (col_1, col_2)                             | Y
    # (col_1)             | (col_1, col_2)                             | Y
    # (col_2)             | (col_1, col_2)                             | N
    # (col_1, col_3)      | (col_1, col_2, col_3)                      | N
    # (col_1, col_2)      | (col_1) where col_2 = "1"                  | Y
    # (col_1, col_2)      | (col_1) where col_2 <= 1                   | N
    # (col_1, col_2)      | (col_1) where col_2 IS NULL                | N
    # (col_1, col_2)      | (col_1) where col_2 = "1" AND COL_1 = "2"  | N
    #
    class IndexCoverage
      PARTIAL_INDEX_REGEX = /(?<!\s)(?>\(*(?<column_name>\b\w+)\s*=\s*(?<column_value>\w+)\)*)(?!\s)/

      def initialize(index, where_hash, order_attributes)
        @index = index
        @where_hash = where_hash
        @order_attributes = order_attributes
      end

      def covers?
        filter_attributes_covered?            &&
          unused_columns_at_end_of_index?     &&
          can_be_used_for_sorting?
      end

      private

      attr_reader :index, :where_hash, :order_attributes

      def filter_attributes_covered?
        partial? ? partial_index_coverage? : full_index_coverage?
      end

      def can_be_used_for_sorting?
        sorts_in_same_order_as_index? &&
          no_filtering_after_sort_columns?
      end

      # All order attributes exist in the query in the same order as they are queried.
      def sorts_in_same_order_as_index?
        (index.columns & order_attributes) == order_attributes
      end

      # All order attributes exist in the query in the same order as they are queried.
      # We rely on sort order to be the same here to assume that anything following the last sort
      # should not be filtered on.
      def no_filtering_after_sort_columns?
        return true if order_attributes.empty?

        (index.columns.split(order_attributes.last).last & filter_attributes).empty?
      end

      # We assume there are <= attributes than columns because filter_attributes_covered has already passed.
      # So we check the count of unqueried columns, take that number from the end of the index,
      # and compare to ensure that any unqueried columns are only at the end of the index.
      # This also helps ensure there are no gaps in the used columns of the index.
      def unused_columns_at_end_of_index?
        remaining_columns = (index.columns - combined_attributes)

        (index.columns.last(remaining_columns.size) - remaining_columns).empty?
      end

      def partial?
        index.where.present?
      end

      def full_index_coverage?
        (filter_attributes - Array(index.columns)).empty?
      end

      def partial_index_coverage?
        return false unless partial_column

        full_index_coverage_with_partial_column? && partial_filter_matches?
      end

      def full_index_coverage_with_partial_column?
        (filter_attributes - Array(index.columns) - Array(partial_column)).empty?
      end

      def combined_attributes
        filter_attributes + order_attributes
      end

      def filter_attributes
        @filter_attributes ||= where_hash.keys
      end

      def partial_filter_matches?
        partial_filter == partial_value
      end

      def partial_filter
        where_hash[partial_column].to_s
      end

      def partial_column
        index_filter['column_name']
      end

      def partial_value
        index_filter['column_value']
      end

      def index_filter
        @index_filter ||= index.where.match(PARTIAL_INDEX_REGEX)&.named_captures.to_h
      end
    end

    def initialize(relation)
      @relation = relation
    end

    # Rewrites the given ActiveRecord::Relation object to
    # utilize the DB indices efficiently.
    #
    # Currently Postgres will produce inefficient query plans which use a `filter_predicate`
    # instead of a `access_predicate` to filter by IN clause contents. This behaviour does a table
    # read of the data for filtering, disregarding the structure of the index and losing any benefit
    # from any sorting applied to the index as it will have to resort the table read data.
    #
    # Rewriting the query using the `unnest` command induces Postgres into using the
    # appropriate index search behaviour for each column in the index by generating a
    # cartesian product between the individual items of the IN filter items and queried table.
    # This means each read column will maintain the sort order provided by the index,
    # avoiding a memory sort node in the final query plan.
    #
    # This will not work if queried columns are not all present in the index, or if unqueried
    # columns exist in the index that are not at the end, as this makes that part of the index
    # useless to Postgres and will result in a table scan anyways from that point.
    #
    #
    # Example usage;
    #
    #   relation = Vulnerabilities::Read.where(state: [1, 4])
    #   relation = relation.order(severity: :desc, vulnerability_id: :desc)
    #
    #   rewriter = UnnestedInFilters::Rewriter.new(relation)
    #   optimized_relation = rewriter.rewrite
    #
    # In the above example. the `relation` object would produce the following SQL query;
    #
    #   SELECT
    #     "vulnerability_reads".*
    #   FROM
    #     "vulnerability_reads"
    #   WHERE
    #     "vulnerability_reads"."state" IN (1, 4)
    #   ORDER BY
    #     "vulnerability_reads"."severity" DESC,
    #     "vulnerability_reads"."vulnerability_id" DESC
    #   LIMIT 20;
    #
    # And the `optimized_relation` object would would produce the following query to
    # utilize the index on (state, severity, vulnerability_id);
    #
    #   SELECT
    #     "vulnerability_reads".*
    #   FROM
    #     unnest('{1, 4}'::smallint[]) AS "states" ("state"),
    #     LATERAL (
    #       SELECT
    #         "vulnerability_reads".*
    #       FROM
    #         "vulnerability_reads"
    #       WHERE
    #         (vulnerability_reads."state" = "states"."state")
    #       ORDER BY
    #         "vulnerability_reads"."severity" DESC,
    #         "vulnerability_reads"."vulnerability_id" DESC
    #       LIMIT 20) AS vulnerability_reads
    #   ORDER BY
    #     "vulnerability_reads"."severity" DESC,
    #     "vulnerability_reads"."vulnerability_id" DESC
    #   LIMIT 20
    #
    # If one of the columns being used for filtering or ordering is the primary key,
    # then the query will be further optimized to use an index-only scan for initial filtering
    # before selecting all columns using the primary key.
    #
    # Using the prior query as an example, where `vulnerability_id` is the primary key,
    # This will be rewritten to:
    #
    #   SELECT
    #     "vulnerability_reads".*
    #   FROM
    #     "vulnerability_reads"
    #   WHERE
    #     "vulnerability_reads"."vulnerability_id"
    #   IN (
    #     SELECT
    #       "vulnerability_reads"."vulnerability_id"
    #     FROM
    #       unnest('{1, 4}'::smallint[]) AS "states" ("state"),
    #       LATERAL (
    #         SELECT
    #           "vulnerability_reads"."vulnerability_id"
    #         FROM
    #           "vulnerability_reads"
    #         WHERE
    #           (vulnerability_reads."state" = "states"."state")
    #         ORDER BY
    #           "vulnerability_reads"."severity" DESC,
    #           "vulnerability_reads"."vulnerability_id" DESC
    #           LIMIT 20
    #         ) AS vulnerability_reads
    #      )
    #   ORDER BY
    #     "vulnerability_reads"."severity" DESC,
    #     "vulnerability_reads"."vulnerability_id" DESC
    #   LIMIT 20
    def rewrite
      log_rewrite

      return filter_query unless primary_key_present?

      index_only_filter_query
    end

    def rewrite?
      strong_memoize(:rewrite) do
        in_filters.present? && has_index_coverage?
      end
    end

    private

    attr_reader :relation

    delegate :model, :order_values, :limit_value, :where_values_hash, :where_clause, to: :relation, private: true

    def log_rewrite
      ::Gitlab::AppLogger.info(message: 'Query is being rewritten by `UnnestedInFilters`', model: model.name)
    end

    def filter_query
      model.from(from).then { |relation| add_relation_defaults(relation) }
    end

    def index_only_filter_query
      model.where(model.primary_key => filter_query.select(model.primary_key))
           .then { |relation| add_relation_defaults(relation) }
    end

    def add_relation_defaults(new_relation)
      new_relation.limit(limit_value)
                  .order(order_values)
                  .includes(relation.includes_values)
                  .preload(relation.preload_values)
                  .eager_load(relation.eager_load_values)
    end

    def from
      [value_tables.map(&:to_sql) + [lateral]].join(', ')
    end

    def lateral
      "LATERAL (#{join_relation.to_sql}) AS #{model.table_name}"
    end

    def join_relation
      join_relation = value_tables.reduce(unscoped_relation) do |memo, tmp_table|
        memo.where(tmp_table.as_predicate)
      end

      join_relation = join_relation.select(combined_attributes) if primary_key_present?

      join_relation
    end

    def unscoped_relation
      relation.unscope(where: in_filters.keys)
    end

    def in_filters
      @in_filters ||= arel_in_nodes.each_with_object({}) { |node, memo| memo[node.left.name] = node.right }
    end

    def model_column_names
      @model_column_names ||= model.columns.map(&:name)
    end

    # Actively filter any nodes that don't belong to the primary queried table to prevent sql type resolution issues
    # Context: https://gitlab.com/gitlab-org/gitlab/-/issues/370271#note_1151019824
    def arel_in_nodes
      where_clause_arel_nodes
        .select { |arel_node| in_predicate?(arel_node) }
        .select { |arel_node| model_column_names.include?(arel_node.left.name) }
    end

    # `ActiveRecord::WhereClause#ast` is returning a single node when there is only one
    # predicate but returning an `Arel::Nodes::And` node if there are more than one predicates.
    # This is why we are checking the returned object responds to `children` or not.
    def where_clause_arel_nodes
      return [where_clause_ast] unless where_clause_ast.respond_to?(:children)

      where_clause_ast.children
    end

    def where_clause_ast
      @where_clause_ast ||= where_clause.ast
    end

    def in_predicate?(arel_node)
      arel_node.is_a?(Arel::Nodes::HomogeneousIn) || arel_node.is_a?(Arel::Nodes::In)
    end

    def has_index_coverage?
      indices.any?(&:covers?)
    end

    def primary_key_present?
      combined_attributes.include?(model.primary_key)
    end

    def combined_attributes
      filter_attributes + order_attributes
    end

    def filter_attributes
      @filter_attributes ||= where_clause.to_h.keys
    end

    def order_attributes
      @order_attributes ||= order_values.flat_map { |order_value| extract_column_name(order_value) }
    end

    def extract_column_name(order_value)
      case order_value
      when Arel::Nodes::Ordering
        order_value.expr.name
      when ::Gitlab::Pagination::Keyset::Order
        order_value.attribute_names
      end
    end

    def indices
      model.connection.schema_cache.indexes(model.table_name).map do |index|
        IndexCoverage.new(index, where_clause.to_h, order_attributes)
      end
    end

    def value_tables
      @value_tables ||= in_filters.map do |attribute, values|
        ValueTable.new(model, attribute, values)
      end
    end
  end
end
# rubocop:enable CodeReuse/ActiveRecord
