# frozen_string_literal: true

class AddExternalKeyToEpicsTable < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      add_column :epics, :external_key, :string, limit: 255 # rubocop:disable Migration/PreventStrings
    end
  end

  def down
    with_lock_retries do
      remove_column :epics, :external_key
    end
  end
end
