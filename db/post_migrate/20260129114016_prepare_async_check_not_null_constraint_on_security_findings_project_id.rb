# frozen_string_literal: true

class PrepareAsyncCheckNotNullConstraintOnSecurityFindingsProjectId < Gitlab::Database::Migration[2.3]
  milestone '18.9'

  TABLE_NAME = :security_findings
  COLUMN_NAME = :project_id

  def up
    constraint_name = check_constraint_name(TABLE_NAME, COLUMN_NAME, 'not_null')

    prepare_async_check_constraint_validation TABLE_NAME, name: constraint_name
  end

  def down
    constraint_name = check_constraint_name(TABLE_NAME, COLUMN_NAME, 'not_null')

    unprepare_async_check_constraint_validation TABLE_NAME, name: constraint_name
  end
end
