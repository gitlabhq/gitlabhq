# frozen_string_literal: true

module LooseForeignKeys
  # rubocop: disable CodeReuse/ActiveRecord
  class CleanerService
    DELETE_LIMIT = 1000
    UPDATE_LIMIT = 500

    delegate :connection, to: :model

    def initialize(model:, foreign_key_definition:, deleted_parent_records:, with_skip_locked: false)
      @model = model
      @foreign_key_definition = foreign_key_definition
      @deleted_parent_records = deleted_parent_records
      @with_skip_locked = with_skip_locked
    end

    def execute
      result = connection.execute(build_query)

      { affected_rows: result.cmd_tuples, table: foreign_key_definition.to_table }
    end

    def async_delete?
      foreign_key_definition.on_delete == :async_delete
    end

    def async_nullify?
      foreign_key_definition.on_delete == :async_nullify
    end

    private

    attr_reader :model, :foreign_key_definition, :deleted_parent_records, :with_skip_locked

    def build_query
      query = if async_delete?
                delete_query
              elsif async_nullify?
                update_query
              else
                raise "Invalid on_delete argument: #{foreign_key_definition.on_delete}"
              end

      unless query.include?(%{"#{foreign_key_definition.column}" IN (})
        raise("FATAL: foreign key condition is missing from the generated query: #{query}")
      end

      query
    end

    def arel_table
      @arel_table ||= model.arel_table
    end

    def primary_keys
      @primary_keys ||= connection.primary_keys(model.table_name).map { |key| arel_table[key] }
    end

    def quoted_table_name
      @quoted_table_name ||= Arel.sql(connection.quote_table_name(model.table_name))
    end

    def delete_query
      query = Arel::DeleteManager.new
      query.from(quoted_table_name)

      add_in_query_with_limit(query, DELETE_LIMIT)
    end

    def update_query
      query = Arel::UpdateManager.new
      query.table(quoted_table_name)
      query.set([[arel_table[foreign_key_definition.column], nil]])

      add_in_query_with_limit(query, UPDATE_LIMIT)
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
      in_query.where(arel_table[foreign_key_definition.column].in(deleted_parent_records.map(&:primary_key_value)))
      in_query.projections = primary_keys
      in_query.take(limit)
      in_query.lock(Arel.sql('FOR UPDATE SKIP LOCKED')) if with_skip_locked
      in_query
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord
end
