# frozen_string_literal: true

class AddAutoAssignDuoProNamespaceSettings < Gitlab::Database::Migration[2.2]
  milestone '17.0'

  def change
    add_column :namespace_settings, :enable_auto_assign_gitlab_duo_pro_seats, :boolean, default: false, null: false
  end
end
