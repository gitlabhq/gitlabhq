# frozen_string_literal: true

module LooseForeignKeys
  # rubocop: disable CodeReuse/ActiveRecord
  class CleanerService
    DELETE_LIMIT = 1000
    UPDATE_LIMIT = 500

    def initialize(loose_foreign_key_definition:, connection:, deleted_parent_records:, logger: Sidekiq.logger, with_skip_locked: false)
      @loose_foreign_key_definition = loose_foreign_key_definition
      @connection = connection
      @deleted_parent_records = deleted_parent_records
      @with_skip_locked = with_skip_locked
      @logger = logger
    end

    def execute
      result = connection.execute(build_query)

      { affected_rows: result.cmd_tuples, table: loose_foreign_key_definition.from_table }
    end

    def async_delete?
      loose_foreign_key_definition.on_delete == :async_delete
    end

    def async_nullify?
      loose_foreign_key_definition.on_delete == :async_nullify
    end

    def update_column_to?
      loose_foreign_key_definition.on_delete == :update_column_to
    end

    private

    attr_reader :loose_foreign_key_definition, :connection, :deleted_parent_records, :with_skip_locked, :logger

    def build_query
      query = if async_delete?
                delete_query
              elsif async_nullify?
                update_query
              elsif update_column_to?
                update_target_column_query
              else
                logger.error("Invalid on_delete argument: #{loose_foreign_key_definition.on_delete}")
                return ""
              end

      quoted_fk_col = connection.quote_column_name(loose_foreign_key_definition.column)
      unless query.include?(%(= "parent".#{quoted_fk_col})) || query.include?("#{quoted_fk_col} IN (")
        logger.error("FATAL: foreign key condition is missing from the generated query: #{query}")
        return ""
      end

      query
    end

    def arel_table
      @arel_table ||= Arel::Table.new(loose_foreign_key_definition.from_table)
    end

    def primary_keys
      @primary_keys ||= connection.primary_keys(loose_foreign_key_definition.from_table).map { |key| arel_table[key] }
    end

    def quoted_table_name
      @quoted_table_name ||= Arel.sql(connection.quote_table_name(loose_foreign_key_definition.from_table))
    end

    def delete_query
      query = Arel::DeleteManager.new
      query.from(quoted_table_name)

      add_in_query_with_limit(query, loose_foreign_key_definition.options[:delete_limit] || DELETE_LIMIT)
    end

    def update_query
      query = Arel::UpdateManager.new
      query.table(quoted_table_name)
      query.set([[arel_table[loose_foreign_key_definition.column], nil]])

      add_in_query_with_limit(query, UPDATE_LIMIT)
    end

    def update_target_column_query
      column, value = loose_foreign_key_definition.options.values_at(:target_column, :target_value)

      query = Arel::UpdateManager.new
      query.table(quoted_table_name)
      query.set([[arel_table[column], value]])

      columns = Arel::Nodes::Grouping.new(primary_keys)
      query.where(columns.in(in_query_with_limit(UPDATE_LIMIT, exclude_condition: [column, value]))).to_sql
    end

    # IN query with one or composite primary key
    # WHERE (primary_key1, primary_key2) IN (subselect)
    def add_in_query_with_limit(query, limit)
      columns = Arel::Nodes::Grouping.new(primary_keys)
      query.where(columns.in(in_query_with_limit(limit))).to_sql
    end

    def in_query_with_limit(limit, exclude_condition: nil)
      if Feature.enabled?(:loose_foreign_keys_lateral_query, Feature.current_request)
        lateral_in_query_with_limit(limit, exclude_condition: exclude_condition)
      else
        legacy_in_query_with_limit(limit, exclude_condition: exclude_condition)
      end
    end

    # Builds a lateral sub-query to avoid plan flip / sequential scans.
    # The LATERAL join forces one index seek per parent ID instead
    # of a single scan for all IDs, and the outer LIMIT caps total rows returned.
    #
    # SELECT "lateral_rows".pk FROM (VALUES (1), (2), (3)) AS parent(fk),
    # LATERAL (
    #   SELECT "table".pk FROM "table"
    #   WHERE "table".fk = "parent".fk
    #   LIMIT N
    #   [FOR UPDATE SKIP LOCKED]
    # ) lateral_rows
    # LIMIT N
    def lateral_in_query_with_limit(limit, exclude_condition: nil)
      fk_col = loose_foreign_key_definition.column
      parent_table = Arel::Table.new('parent')
      lateral_table = Arel::Table.new('lateral_rows')

      inner = Arel::SelectManager.new
      inner.from(quoted_table_name)
      inner.projections = primary_keys
      inner.where(arel_table[fk_col].eq(parent_table[fk_col]))
      loose_foreign_key_definition.options[:conditions]&.each do |condition|
        inner.where(arel_table[condition[:column]].eq(condition[:value]))
      end

      if exclude_condition
        col, val = exclude_condition
        inner.where(arel_table[col].not_eq(val))
      end

      inner.lock(Arel.sql('FOR UPDATE SKIP LOCKED')) if with_skip_locked
      inner.take(limit)

      quoted_fk_col = connection.quote_column_name(fk_col)
      values_list = Arel::Nodes::ValuesList.new(deleted_parent_records.map { |r| [r.primary_key_value] })

      outer = Arel::SelectManager.new
      outer.from(Arel.sql("(#{values_list.to_sql}) AS parent(#{quoted_fk_col}), LATERAL (#{inner.to_sql}) lateral_rows"))
      outer.projections = primary_keys.map { |pk| lateral_table[pk.name] }
      outer.take(limit)
      outer
    end

    # Builds: SELECT primary_keys FROM table WHERE foreign_key IN (1, 2, 3) LIMIT N
    def legacy_in_query_with_limit(limit, exclude_condition: nil)
      in_query = Arel::SelectManager.new
      in_query.from(quoted_table_name)
      in_query.where(arel_table[loose_foreign_key_definition.column].in(deleted_parent_records.map(&:primary_key_value)))
      loose_foreign_key_definition.options[:conditions]&.each do |condition|
        in_query.where(arel_table[condition[:column]].eq(condition[:value]))
      end

      if exclude_condition
        col, val = exclude_condition
        in_query.where(arel_table[col].not_eq(val))
      end

      in_query.projections = primary_keys
      in_query.take(limit)
      in_query.lock(Arel.sql('FOR UPDATE SKIP LOCKED')) if with_skip_locked
      in_query
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord
end
