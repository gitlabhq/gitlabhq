# frozen_string_literal: true

class AddDisabledAtToSecretsManagerNamespaceEnrollments < Gitlab::Database::Migration[2.3]
  milestone '19.4'

  def change
    add_column :secrets_manager_namespace_enrollments, :disabled_at, :datetime_with_timezone
  end
end
