# frozen_string_literal: true

class AddBetaToSecretsManagerNamespaceEnrollments < Gitlab::Database::Migration[2.3]
  milestone '19.3'

  def change
    add_column :secrets_manager_namespace_enrollments, :beta, :boolean, default: true, null: false
  end
end
