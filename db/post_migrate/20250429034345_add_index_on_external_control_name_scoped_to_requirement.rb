# frozen_string_literal: true

class AddIndexOnExternalControlNameScopedToRequirement < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.0'

  TABLE_NAME = :compliance_requirements_controls
  INDEX_NAME = :i_unique_external_control_name_per_requirement

  def up
    add_concurrent_index TABLE_NAME,
      [:compliance_requirement_id, :external_control_name],
      unique: true,
      where: "external_control_name IS NOT NULL",
      name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name TABLE_NAME, INDEX_NAME
  end
end
