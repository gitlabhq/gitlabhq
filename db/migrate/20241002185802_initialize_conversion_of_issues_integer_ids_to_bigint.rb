# frozen_string_literal: true

class InitializeConversionOfIssuesIntegerIdsToBigint < Gitlab::Database::Migration[2.2]
  milestone '17.5'

  disable_ddl_transaction!

  TABLE = :issues
  COLUMNS = %i[author_id closed_by_id duplicated_to_id id last_edited_by_id milestone_id moved_to_id
    project_id promoted_to_epic_id updated_by_id]

  def up
    initialize_conversion_of_integer_to_bigint(TABLE, COLUMNS)
  end

  def down
    revert_initialize_conversion_of_integer_to_bigint(TABLE, COLUMNS)
  end
end
