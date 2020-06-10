# frozen_string_literal: true

class AddCiRefIdToCiPipelines < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      add_column :ci_pipelines, :ci_ref_id, :bigint
    end
  end

  def down
    with_lock_retries do
      remove_column :ci_pipelines, :ci_ref_id, :bigint
    end
  end
end
