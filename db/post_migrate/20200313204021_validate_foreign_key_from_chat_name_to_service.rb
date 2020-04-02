# frozen_string_literal: true

class ValidateForeignKeyFromChatNameToService < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers
  DOWNTIME = false

  def up
    validate_foreign_key :chat_names, :service_id
  end

  def down
    # no-op
  end
end
