# frozen_string_literal: true

class AddSecurityFindingsProjectIdTrigger < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  def up
    install_sharding_key_assignment_trigger(
      table: :security_findings,
      sharding_key: :project_id,
      parent_table: :vulnerability_scanners,
      parent_sharding_key: :project_id,
      foreign_key: :scanner_id
    )
  end

  def down
    remove_sharding_key_assignment_trigger(
      table: :security_findings,
      sharding_key: :project_id,
      parent_table: :vulnerability_scanners,
      parent_sharding_key: :project_id,
      foreign_key: :scanner_id
    )
  end
end
