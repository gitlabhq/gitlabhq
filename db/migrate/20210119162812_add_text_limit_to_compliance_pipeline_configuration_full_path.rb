# frozen_string_literal: true

class AddTextLimitToCompliancePipelineConfigurationFullPath < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_text_limit :compliance_management_frameworks, :pipeline_configuration_full_path, 255
  end

  def down
    remove_text_limit :compliance_management_frameworks, :pipeline_configuration_full_path
  end
end
