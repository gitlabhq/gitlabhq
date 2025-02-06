# frozen_string_literal: true

class AddSendEmailColumnToDependencyListExports < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  def change
    add_column :dependency_list_exports, :send_email, :boolean, null: false, default: false, if_not_exists: true
  end
end
