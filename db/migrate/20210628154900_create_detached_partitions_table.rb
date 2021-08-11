# frozen_string_literal: true

class CreateDetachedPartitionsTable < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  def change
    create_table_with_constraints :detached_partitions do |t|
      t.timestamps_with_timezone null: false
      t.datetime_with_timezone :drop_after, null: false
      t.text :table_name, null: false

      # Postgres identifier names can be up to 63 bytes
      # See https://www.postgresql.org/docs/current/sql-syntax-lexical.html#SQL-SYNTAX-IDENTIFIERS
      t.text_limit :table_name, 63
    end
  end
end
