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

      unless query.include?(%{"#{loose_foreign_key_definition.column}" IN (})
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

      add_in_query_with_limit(query, DELETE_LIMIT)
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
      in_query = in_query_with_limit(UPDATE_LIMIT)
      in_query.where(arel_table[column].not_eq(value))
      query.where(columns.in(in_query)).to_sql
    end

    # IN query with one or composite primary key
    # WHERE (primary_key1, primary_key2) IN (subselect)
    def add_in_query_with_limit(query, limit)
      columns = Arel::Nodes::Grouping.new(primary_keys)
      query.where(columns.in(in_query_with_limit(limit))).to_sql
    end

    # Builds the following sub-query
    # SELECT primary_keys FROM table WHERE foreign_key IN (1, 2, 3) LIMIT N
    def in_query_with_limit(limit)
      in_query = Arel::SelectManager.new
      in_query.from(quoted_table_name)
      in_query.where(arel_table[loose_foreign_key_definition.column].in(deleted_parent_records.map(&:primary_key_value)))
      loose_foreign_key_definition.options[:conditions]&.each do |condition|
        in_query.where(arel_table[condition[:column]].eq(condition[:value]))
      end
      in_query.projections = primary_keys
      in_query.take(limit)
      in_query.lock(Arel.sql('FOR UPDATE SKIP LOCKED')) if with_skip_locked
      in_query
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord
end
