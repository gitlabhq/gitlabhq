# frozen_string_literal: true

class AddFoundationalFlowsAvailability < Gitlab::Database::Migration[2.3]
  milestone '18.7'

  def up
    add_column :project_settings, :duo_foundational_flows_enabled, :boolean,
      if_not_exists: true
  end

  def down
    remove_column :project_settings, :duo_foundational_flows_enabled, if_exists: true
  end
end
