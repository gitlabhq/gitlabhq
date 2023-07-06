# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class PrepareRemovalIndexDeploymentsOnProjectIdSha < Gitlab::Database::Migration[2.1]
  INDEX_NAME = 'index_deployments_on_project_id_sha'

  # TODO: Index to be destroyed synchronously in https://gitlab.com/gitlab-org/gitlab/-/issues/402512
  def up
    prepare_async_index_removal :deployments, %i[project_id sha], name: INDEX_NAME
  end

  def down
    unprepare_async_index :deployments, %i[project_id sha], name: INDEX_NAME
  end
end
