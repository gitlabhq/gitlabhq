# frozen_string_literal: true

class AddRefCountToPushEventPayloads < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :push_event_payloads, :ref_count, :integer
  end
end
