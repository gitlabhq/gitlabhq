# frozen_string_literal: true

class AddPipelineConfigurationFullPathToCompliancePipeline < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  # rubocop:disable Migration/AddLimitToTextColumns
  # limit is added in 20210119162812_add_text_limit_to_compliance_pipeline_configuration_full_path.rb
  def up
    add_column :compliance_management_frameworks, :pipeline_configuration_full_path, :text
  end
  # rubocop:enable Migration/AddLimitToTextColumns

  def down
    remove_column :compliance_management_frameworks, :pipeline_configuration_full_path
  end
end
