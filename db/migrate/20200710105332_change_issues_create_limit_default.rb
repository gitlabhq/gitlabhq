# frozen_string_literal: true

class ChangeIssuesCreateLimitDefault < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      change_column_default :application_settings, :issues_create_limit, from: 300, to: 0
    end
  end

  def down
    with_lock_retries do
      change_column_default :application_settings, :issues_create_limit, from: 0, to: 300
    end
  end
end
