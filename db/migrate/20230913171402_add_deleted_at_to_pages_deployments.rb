# frozen_string_literal: true

class AddDeletedAtToPagesDeployments < Gitlab::Database::Migration[2.1]
  def change
    add_column :pages_deployments, :deleted_at, :datetime_with_timezone, null: true
  end
end
