# frozen_string_literal: true

class DropIndexOnExternalNameForComplianceControls < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.1'

  TABLE_NAME = :compliance_requirements_controls
  INDEX_NAME = :i_unique_external_control_name_per_requirement
  NEW_INDEX_NAME = :i_uniq_external_control_name_per_requirement

  def up
    add_concurrent_index TABLE_NAME,
      [:compliance_requirement_id, :external_control_name],
      unique: true,
      where: "external_control_name IS NOT NULL AND external_control_name != ''",
      name: NEW_INDEX_NAME

    remove_concurrent_index_by_name TABLE_NAME, name: INDEX_NAME
  end

  def down
    add_concurrent_index TABLE_NAME,
      [:compliance_requirement_id, :external_control_name],
      unique: true,
      where: "external_control_name IS NOT NULL",
      name: INDEX_NAME

    remove_concurrent_index_by_name TABLE_NAME, name: NEW_INDEX_NAME
  end
end
