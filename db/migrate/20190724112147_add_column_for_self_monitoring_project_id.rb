# frozen_string_literal: true

class AddColumnForSelfMonitoringProjectId < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def change
    add_reference(
      :application_settings,
      :instance_administration_project,
      index: { name: 'index_applicationsettings_on_instance_administration_project_id' },
      foreign_key: { to_table: :projects, on_delete: :nullify }
    )
  end
end
