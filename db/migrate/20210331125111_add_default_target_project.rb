# frozen_string_literal: true

class AddDefaultTargetProject < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  def up
    with_lock_retries do
      add_column :project_settings, :mr_default_target_self, :boolean, default: false, null: false
    end
  end

  def down
    with_lock_retries do
      remove_column :project_settings, :mr_default_target_self
    end
  end
end
