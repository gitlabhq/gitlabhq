# frozen_string_literal: true

class AddProjectIdUserIdStatusRefIndexToCiPipelines < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  SOURCE_PARENT_PIPELINE = 12

  def up
    add_concurrent_index(
      :ci_pipelines,
      [:project_id, :user_id, :status, :ref],
      where: "source != #{SOURCE_PARENT_PIPELINE}"
    )
  end

  def down
    remove_concurrent_index(
      :ci_pipelines,
      [:project_id, :user_id, :status, :ref],
      where: "source != #{SOURCE_PARENT_PIPELINE}"
    )
  end
end
