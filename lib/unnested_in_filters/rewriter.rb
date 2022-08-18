# frozen_string_literal: true

# rubocop:disable CodeReuse/ActiveRecord (This module is generating ActiveRecord relations therefore using AR methods is necessary)
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
        "unnest(#{serialized_values}::#{sql_type}[]) AS #{table_name}(#{column_name})"
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
        values.is_a?(Arel::Nodes::SelectStatement) ? "ARRAY(#{serialized_arel_value})" : serialized_array_values
      end

      def serialized_arel_value
        visitor.compile(values, unprepared_statement_collector)
      end

      def serialized_array_values
        values.map(&:value)
              .then { array_type.serialize(_1) }
              .then { |array| quote(array) }
      end

      def array_type
        ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Array.new(attribute_types[attribute])
      end

      def sql_type
        column.sql_type_metadata.sql_type
      end

      def column
        columns.find { _1.name == attribute }
      end

      def unprepared_statement_collector
        Arel::Collectors::SubstituteBinds.new(
          connection,
          Arel::Collectors::SQLString.new
        )
      end
    end

    def initialize(relation)
      @relation = relation
    end

    # Rewrites the given ActiveRecord::Relation object to
    # utilize the DB indices efficiently.
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
    def rewrite
      log_rewrite

      model.from(from)
           .limit(limit_value)
           .order(order_values)
           .includes(relation.includes_values)
           .preload(relation.preload_values)
           .eager_load(relation.eager_load_values)
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

    def from
      [value_tables.map(&:to_sql) + [lateral]].join(', ')
    end

    def lateral
      "LATERAL (#{join_relation.to_sql}) AS #{model.table_name}"
    end

    def join_relation
      value_tables.reduce(unscoped_relation) do |memo, tmp_table|
        memo.where(tmp_table.as_predicate)
      end
    end

    def unscoped_relation
      relation.unscope(where: in_filters.keys)
    end

    def in_filters
      @in_filters ||= arel_in_nodes.each_with_object({}) { |node, memo| memo[node.left.name] = node.right }
    end

    def arel_in_nodes
      where_clause_arel_nodes.select(&method(:in_predicate?))
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
      indices.any? do |index|
        (filter_attributes - Array(index.columns)).empty? && # all the filter attributes are indexed
          index.columns.last(order_attributes.length) == order_attributes && # index can be used in sorting
          (index.columns - (filter_attributes + order_attributes)).empty? # there is no other columns in the index
      end
    end

    def filter_attributes
      @filter_attributes ||= where_values_hash.keys
    end

    def order_attributes
      @order_attributes ||= order_values.flat_map(&method(:extract_column_name))
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
      model.connection.schema_cache.indexes(model.table_name)
    end

    def value_tables
      @value_tables ||= in_filters.map do |attribute, values|
        ValueTable.new(model, attribute, values)
      end
    end
  end
end
