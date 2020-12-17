# frozen_string_literal: true

class CreateNamespaceOnboardingActions < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      create_table :namespace_onboarding_actions do |t|
        t.references :namespace, index: true, null: false, foreign_key: { on_delete: :cascade }
        t.datetime_with_timezone :created_at, null: false
        t.integer :action, limit: 2, null: false
      end
    end
  end

  def down
    with_lock_retries do
      drop_table :namespace_onboarding_actions
    end
  end
end
