# frozen_string_literal: true

class DropNotNullToCiBuildSourcesSource < Gitlab::Database::Migration[2.2]
  milestone '17.6'
  disable_ddl_transaction!

  TABLE_NAME = :p_ci_build_sources
  COLUMN_NAME = :source

  def up
    change_column_null TABLE_NAME, COLUMN_NAME, true
  end

  def down
    change_column_null TABLE_NAME, COLUMN_NAME, false
  end
end
