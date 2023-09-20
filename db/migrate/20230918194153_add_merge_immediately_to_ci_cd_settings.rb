# frozen_string_literal: true

class AddMergeImmediatelyToCiCdSettings < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def up
    add_column :project_ci_cd_settings, :merge_trains_skip_train_allowed, :boolean, default: false, null: false
  end

  def down
    remove_column :project_ci_cd_settings, :merge_trains_skip_train_allowed
  end
end
