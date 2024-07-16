# frozen_string_literal: true

class AddProtectedTagCreateAccessLevelsProjectIdTrigger < Gitlab::Database::Migration[2.2]
  milestone '17.2'

  def up
    install_sharding_key_assignment_trigger(
      table: :protected_tag_create_access_levels,
      sharding_key: :project_id,
      parent_table: :protected_tags,
      parent_sharding_key: :project_id,
      foreign_key: :protected_tag_id
    )
  end

  def down
    remove_sharding_key_assignment_trigger(
      table: :protected_tag_create_access_levels,
      sharding_key: :project_id,
      parent_table: :protected_tags,
      parent_sharding_key: :project_id,
      foreign_key: :protected_tag_id
    )
  end
end
