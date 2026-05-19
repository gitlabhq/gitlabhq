# frozen_string_literal: true

class RemoveRedundantConversionColumnsForIssues < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  TABLE_NAME = :issues
  TRIGGER_NAME = 'trigger_22262f5f16d8'
  COLUMNS = {
    author_id: {},
    closed_by_id: {},
    duplicated_to_id: {},
    id: { null: false, default: 0 },
    last_edited_by_id: {},
    milestone_id: {},
    moved_to_id: {},
    project_id: {},
    promoted_to_epic_id: {},
    updated_by_id: {}
  }

  def up
    return if integer_columns.any?

    remove_rename_triggers(TABLE_NAME, TRIGGER_NAME)

    change_table TABLE_NAME do |t|
      COLUMNS.each_key do |column|
        t.remove convert_to_bigint_column(column)
      end
    end
  end

  def down
    return if integer_columns.any?

    change_table TABLE_NAME do |t|
      COLUMNS.each do |column, options|
        t.bigint convert_to_bigint_column(column), **options
      end
    end

    install_rename_triggers(TABLE_NAME, *column_pair)
  end

  def integer_columns
    columns(TABLE_NAME).select do |column|
      COLUMNS.include?(column.name.to_sym) && column.sql_type == 'integer'
    end
  end

  def column_pair
    [
      COLUMNS.map { |name, _| name },
      COLUMNS.map { |name, _| convert_to_bigint_column(name) }
    ]
  end
end
