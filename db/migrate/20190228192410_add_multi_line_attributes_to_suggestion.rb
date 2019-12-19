# frozen_string_literal: true

class AddMultiLineAttributesToSuggestion < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    # rubocop:disable Migration/AddColumnWithDefault
    add_column_with_default :suggestions, :lines_above, :integer, default: 0, allow_null: false
    add_column_with_default :suggestions, :lines_below, :integer, default: 0, allow_null: false
    add_column_with_default :suggestions, :outdated, :boolean, default: false, allow_null: false
    # rubocop:enable Migration/AddColumnWithDefault
  end

  def down
    remove_columns :suggestions, :outdated, :lines_above, :lines_below
  end
end
