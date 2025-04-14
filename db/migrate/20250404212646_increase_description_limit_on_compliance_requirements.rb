# frozen_string_literal: true

class IncreaseDescriptionLimitOnComplianceRequirements < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.11'

  def up
    remove_text_limit :compliance_requirements, :description
    add_text_limit :compliance_requirements, :description, 500
  end

  def down
    remove_text_limit :compliance_requirements, :description
    add_text_limit :compliance_requirements, :description, 255
  end
end
