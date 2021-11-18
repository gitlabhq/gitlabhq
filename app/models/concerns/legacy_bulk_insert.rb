# frozen_string_literal: true

module LegacyBulkInsert
  extend ActiveSupport::Concern

  class_methods do
    # Bulk inserts a number of rows into a table, optionally returning their
    # IDs.
    #
    # This method is deprecated, and you should use the BulkInsertSafe module
    # instead.
    #
    # table - The name of the table to insert the rows into.
    # rows - An Array of Hash instances, each mapping the columns to their
    #        values.
    # return_ids - When set to true the return value will be an Array of IDs of
    #              the inserted rows
    # disable_quote - A key or an Array of keys to exclude from quoting (You
    #                 become responsible for protection from SQL injection for
    #                 these keys!)
    # on_conflict - Defines an upsert. Values can be: :disabled (default) or
    #               :do_nothing
    def legacy_bulk_insert(table, rows, return_ids: false, disable_quote: [], on_conflict: nil)
      return if rows.empty?

      keys = rows.first.keys
      columns = keys.map { |key| connection.quote_column_name(key) }

      disable_quote = Array(disable_quote).to_set
      tuples = rows.map do |row|
        keys.map do |k|
          disable_quote.include?(k) ? row[k] : connection.quote(row[k])
        end
      end

      sql = <<-EOF
        INSERT INTO #{table} (#{columns.join(', ')})
        VALUES #{tuples.map { |tuple| "(#{tuple.join(', ')})" }.join(', ')}
      EOF

      sql = "#{sql} ON CONFLICT DO NOTHING" if on_conflict == :do_nothing

      sql = "#{sql} RETURNING id" if return_ids

      result = connection.execute(sql)

      if return_ids
        result.values.map { |tuple| tuple[0].to_i }
      else
        []
      end
    end
  end
end
