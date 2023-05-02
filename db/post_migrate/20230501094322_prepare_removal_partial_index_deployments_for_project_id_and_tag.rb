# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class PrepareRemovalPartialIndexDeploymentsForProjectIdAndTag < Gitlab::Database::Migration[2.1]
  INDEX_NAME = 'partial_index_deployments_for_project_id_and_tag'

  # TODO: Index to be destroyed synchronously in https://gitlab.com/gitlab-org/gitlab/-/issues/402516
  def up
    prepare_async_index_removal :deployments, :project_id, name: INDEX_NAME
  end

  def down
    unprepare_async_index :deployments, :project_id, name: INDEX_NAME
  end
end
