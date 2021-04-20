# frozen_string_literal: true

class AddTrialExtensionTypeToGitlabSubscriptions < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    with_lock_retries do
      add_column :gitlab_subscriptions, :trial_extension_type, :smallint
    end
  end

  def down
    with_lock_retries do
      remove_column :gitlab_subscriptions, :trial_extension_type
    end
  end
end
