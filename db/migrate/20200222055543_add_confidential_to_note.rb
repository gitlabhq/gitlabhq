# frozen_string_literal: true
class AddConfidentialToNote < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    with_lock_retries do
      add_column :notes, :confidential, :boolean
    end
  end
end
