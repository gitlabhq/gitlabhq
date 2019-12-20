# frozen_string_literal: true

class CleanupDeployAccessLevelsForRemovedGroups < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def up
    return unless Gitlab.ee?

    delete = <<~SQL
      DELETE FROM protected_environment_deploy_access_levels d
      USING protected_environments p
      WHERE d.protected_environment_id=p.id
        AND d.group_id IS NOT NULL
        AND NOT EXISTS (SELECT 1 FROM project_group_links WHERE project_id=p.project_id AND group_id=d.group_id)
      RETURNING *
    SQL

    # At the time of writing there are 4 such records on GitLab.com,
    # execution time is expected to be around 15ms.
    records = execute(delete)

    logger = Gitlab::BackgroundMigration::Logger.build
    records.to_a.each do |record|
      logger.info record.as_json.merge(message: "protected_environments_deploy_access_levels was deleted")
    end
  end

  def down
    # There is no pragmatic way to restore
    # the records deleted in the `#up` method above.
  end
end
