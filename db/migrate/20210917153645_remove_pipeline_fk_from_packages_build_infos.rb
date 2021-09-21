# frozen_string_literal: true

class RemovePipelineFkFromPackagesBuildInfos < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    with_lock_retries do
      remove_foreign_key_if_exists(:packages_build_infos, :ci_pipelines)
    end
  end

  def down
    add_concurrent_foreign_key(:packages_build_infos, :ci_pipelines, column: :pipeline_id, on_delete: :nullify)
  end
end
