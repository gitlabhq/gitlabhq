# frozen_string_literal: true

class RemoveShimoZentaoIntegrationRecords < Gitlab::Database::Migration[2.1]
  TYPES = %w[Integrations::Shimo Integrations::Zentao]
  BATCH_SIZE = 100

  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    return if Gitlab.jh?

    define_batchable_model(:integrations)
      .where(type_new: TYPES)
      .each_batch(of: BATCH_SIZE) { |relation, _index| relation.delete_all }
  end

  def down
    # no-op
  end
end
