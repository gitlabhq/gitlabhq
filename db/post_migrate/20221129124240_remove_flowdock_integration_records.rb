# frozen_string_literal: true

class RemoveFlowdockIntegrationRecords < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  class Integration < MigrationRecord
    include EachBatch

    self.table_name = 'integrations'
  end

  def up
    Integration.each_batch(of: 1000, column: :id) do |relation|
      relation.delete_by(type_new: 'Integrations::Flowdock')
    end
  end

  def down
    # no-op
  end
end
