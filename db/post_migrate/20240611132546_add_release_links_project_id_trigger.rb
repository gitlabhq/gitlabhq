# frozen_string_literal: true

class AddReleaseLinksProjectIdTrigger < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  def up
    install_sharding_key_assignment_trigger(
      table: :release_links,
      sharding_key: :project_id,
      parent_table: :releases,
      parent_sharding_key: :project_id,
      foreign_key: :release_id
    )
  end

  def down
    remove_sharding_key_assignment_trigger(
      table: :release_links,
      sharding_key: :project_id,
      parent_table: :releases,
      parent_sharding_key: :project_id,
      foreign_key: :release_id
    )
  end
end
