# frozen_string_literal: true

class AddDetectionMethodToVulnerabilitiesFinding < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  def up
    with_lock_retries do
      add_column :vulnerability_occurrences, :detection_method, :smallint, null: false, default: 0
    end
  end

  def down
    with_lock_retries do
      remove_column :vulnerability_occurrences, :detection_method
    end
  end
end
