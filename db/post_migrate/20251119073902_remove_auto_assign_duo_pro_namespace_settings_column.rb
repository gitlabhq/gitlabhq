# frozen_string_literal: true

class RemoveAutoAssignDuoProNamespaceSettingsColumn < Gitlab::Database::Migration[2.3]
  milestone '18.7'

  def change
    remove_column :namespace_settings,
      :enable_auto_assign_gitlab_duo_pro_seats,
      :boolean,
      default: false,
      null: false,
      if_exists: true
  end
end
