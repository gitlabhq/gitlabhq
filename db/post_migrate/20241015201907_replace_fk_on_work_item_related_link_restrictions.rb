# frozen_string_literal: true

class ReplaceFkOnWorkItemRelatedLinkRestrictions < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.6'

  SOURCE_CONSTRAINT_NAME = 'fk_work_item_related_link_restrictions_source_type_id'
  TARGET_CONSTRAINT_NAME = 'fk_work_item_related_link_restrictions_target_type_id'

  def up
    add_concurrent_foreign_key :work_item_related_link_restrictions,
      :work_item_types,
      column: :source_type_id,
      on_delete: :cascade,
      on_update: :cascade,
      name: SOURCE_CONSTRAINT_NAME

    add_concurrent_foreign_key :work_item_related_link_restrictions,
      :work_item_types,
      column: :target_type_id,
      on_delete: :cascade,
      on_update: :cascade,
      name: TARGET_CONSTRAINT_NAME
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :work_item_related_link_restrictions,
        column: :source_type_id,
        name: SOURCE_CONSTRAINT_NAME
      remove_foreign_key_if_exists :work_item_related_link_restrictions,
        column: :target_type_id,
        name: TARGET_CONSTRAINT_NAME
    end
  end
end
