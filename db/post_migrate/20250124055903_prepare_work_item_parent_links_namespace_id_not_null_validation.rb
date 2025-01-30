# frozen_string_literal: true

class PrepareWorkItemParentLinksNamespaceIdNotNullValidation < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.9'

  CONSTRAINT_NAME = :check_e9c0111985

  def up
    prepare_async_check_constraint_validation :work_item_parent_links, name: CONSTRAINT_NAME
  end

  def down
    unprepare_async_check_constraint_validation :work_item_parent_links, name: CONSTRAINT_NAME
  end
end
