# frozen_string_literal: true

class RemoveForeignKeysFromAlertsServiceData < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      remove_foreign_key_if_exists :alerts_service_data, column: :service_id
    end
  end

  def down
    with_lock_retries do
      add_foreign_key :alerts_service_data, :services, column: :service_id, on_delete: :cascade
    end
  end
end
