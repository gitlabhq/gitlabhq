# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class PostPopulateCanPushFromDeployKeysProjects < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  disable_ddl_transaction!

  class DeploysKeyProject < ActiveRecord::Base
    include EachBatch

    self.table_name = 'deploy_keys_projects'
  end

  def up
    DeploysKeyProject.each_batch(of: 10_000) do |batch|
      start_id, end_id = batch.pluck('MIN(id), MAX(id)').first

      execute <<-EOF
        UPDATE deploy_keys_projects
        SET can_push = keys.can_push
        FROM keys
        WHERE deploy_key_id = keys.id
        AND deploy_keys_projects.id BETWEEN #{start_id} AND #{end_id}
      EOF
    end
  end

  def down
    DeploysKeyProject.each_batch(of: 10_000) do |batch|
      start_id, end_id = batch.pluck('MIN(id), MAX(id)').first

      execute <<-EOF
        UPDATE keys
        SET can_push = deploy_keys_projects.can_push
        FROM deploy_keys_projects
        WHERE deploy_keys_projects.deploy_key_id = keys.id
        AND deploy_keys_projects.id BETWEEN #{start_id} AND #{end_id}
      EOF
    end
  end
end
