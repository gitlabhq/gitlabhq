# frozen_string_literal: true

class RemoveNamespaceIdForeignKeyOnNamespaceOnboardingActions < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      remove_foreign_key :namespace_onboarding_actions, :namespaces
    end
  end

  def down
    with_lock_retries do
      add_foreign_key :namespace_onboarding_actions, :namespaces, on_delete: :cascade
    end
  end
end
