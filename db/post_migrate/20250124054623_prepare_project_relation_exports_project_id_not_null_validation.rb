# frozen_string_literal: true

class PrepareProjectRelationExportsProjectIdNotNullValidation < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.9'

  CONSTRAINT_NAME = :check_f461e3537f

  def up
    prepare_async_check_constraint_validation :project_relation_exports, name: CONSTRAINT_NAME
  end

  def down
    unprepare_async_check_constraint_validation :project_relation_exports, name: CONSTRAINT_NAME
  end
end
