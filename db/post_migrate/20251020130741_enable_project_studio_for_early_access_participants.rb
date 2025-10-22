# frozen_string_literal: true

class EnableProjectStudioForEarlyAccessParticipants < Gitlab::Database::Migration[2.3]
  milestone '18.6'
  restrict_gitlab_migration gitlab_schema: :gitlab_main
  disable_ddl_transaction!

  NAMESPACE_BATCH_SIZE = 50
  USER_BATCH_SIZE = 200

  class UserPreference < MigrationRecord
    self.table_name = :user_preferences
  end

  class NamespaceSetting < MigrationRecord
    self.table_name = :namespace_settings

    include EachBatch
  end

  def up
    return unless ::Gitlab.com?

    # Iterate over namespaces with experiment features enabled
    NamespaceSetting.where(experiment_features_enabled: true).each_batch(of: NAMESPACE_BATCH_SIZE) do |batch|
      namespace_ids = batch.pluck(:namespace_id)

      # Find early access participants who are members of these namespaces
      user_ids_to_update = execute(<<~SQL).pluck('user_id')
        SELECT DISTINCT m.user_id
        FROM members m
        WHERE m.source_type = 'Namespace'
        AND m.source_id IN (#{namespace_ids.join(',')})
      SQL

      next if user_ids_to_update.empty?

      user_ids_to_update.each_slice(USER_BATCH_SIZE) do |slice|
        UserPreference
          .where(user_id: slice).update_all(project_studio_enabled: true, early_access_studio_participant: true)

        sleep 0.1
      end
    end
  end

  def down
    # no-op
  end
end
