# frozen_string_literal: true

class AddSppRepositoryPipelineAccessCascadingSetting < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::MigrationHelpers::CascadingNamespaceSettings

  enable_lock_retries!

  milestone '17.4'

  def up
    add_cascading_namespace_setting :spp_repository_pipeline_access, :boolean, default: false, null: false
  end

  def down
    remove_cascading_namespace_setting :spp_repository_pipeline_access
  end
end
