# frozen_string_literal: true

class AddOptionalToCiBuildNeeds < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      add_column :ci_build_needs, :optional, :boolean, default: false, null: false
    end
  end

  def down
    with_lock_retries do
      remove_column :ci_build_needs, :optional
    end
  end
end
