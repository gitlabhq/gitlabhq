# frozen_string_literal: true

class UpdateUniqueIndexForComplianceRequirementsControls < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  OLD_UNIQUE_INDEX_NAME = 'uniq_compliance_requirements_controls_name_requirement_id'
  NEW_UNIQUE_INDEX_NAME = 'uniq_compliance_controls_requirement_id_and_name'
  INDEX_REQUIREMENT_ID = 'idx_compliance_requirements_controls_on_requirement_id'

  disable_ddl_transaction!

  def up
    add_concurrent_index :compliance_requirements_controls,
      [:compliance_requirement_id, :name],
      name: NEW_UNIQUE_INDEX_NAME,
      unique: true,
      where: "control_type != 1"

    add_concurrent_index :compliance_requirements_controls, :compliance_requirement_id, name: INDEX_REQUIREMENT_ID
    remove_concurrent_index_by_name :compliance_requirements_controls, OLD_UNIQUE_INDEX_NAME
  end

  def down
    add_concurrent_index :compliance_requirements_controls,
      [:compliance_requirement_id, :name],
      name: OLD_UNIQUE_INDEX_NAME,
      unique: true

    remove_concurrent_index_by_name :compliance_requirements_controls, NEW_UNIQUE_INDEX_NAME
    remove_concurrent_index_by_name :compliance_requirements_controls, INDEX_REQUIREMENT_ID
  end
end
