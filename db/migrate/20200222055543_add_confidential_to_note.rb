# frozen_string_literal: true
class AddConfidentialToNote < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      add_column :notes, :confidential, :boolean
    end
  end

  def down
    with_lock_retries do
      remove_column :notes, :confidential
    end
  end
end
