# frozen_string_literal: true

class RemoveInvalidIntegrations < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  BATCH_SIZE = 100

  def up
    loop do
      deleted = Integration.where(type_new: nil).limit(BATCH_SIZE).delete_all

      break if deleted < BATCH_SIZE
    end
  end

  # Isolated version of the Integration model
  class Integration < MigrationRecord
    self.table_name = 'integrations'
    self.inheritance_column = :_type_disabled
  end
end
