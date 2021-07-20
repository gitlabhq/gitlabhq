# frozen_string_literal: true

class RemoveFrameworkColumnFromComplianceManagementFrameworks < ActiveRecord::Migration[6.1]
  def change
    remove_column :project_compliance_framework_settings, :framework, :smallint
  end
end
