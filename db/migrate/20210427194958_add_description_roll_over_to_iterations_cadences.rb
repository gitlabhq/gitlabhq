# frozen_string_literal: true

class AddDescriptionRollOverToIterationsCadences < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  def up
    with_lock_retries do
      add_column :iterations_cadences, :roll_over, :boolean, null: false, default: false
      add_column :iterations_cadences, :description, :text # rubocop:disable Migration/AddLimitToTextColumns
    end
  end

  def down
    with_lock_retries do
      remove_column :iterations_cadences, :roll_over
      remove_column :iterations_cadences, :description
    end
  end
end
