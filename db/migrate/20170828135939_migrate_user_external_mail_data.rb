# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class MigrateUserExternalMailData < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  class User < ActiveRecord::Base
    self.table_name = 'users'

    include EachBatch
  end

  class UserSyncedAttributesMetadata < ActiveRecord::Base
    self.table_name = 'user_synced_attributes_metadata'

    include EachBatch
  end

  def up
    User.each_batch do |batch|
      start_id, end_id = batch.pluck('MIN(id), MAX(id)').first

      execute <<-EOF
        INSERT INTO user_synced_attributes_metadata (user_id, provider, email_synced)
        SELECT id, email_provider, external_email
        FROM users
        WHERE external_email = TRUE
        AND NOT EXISTS (
          SELECT true
          FROM user_synced_attributes_metadata
          WHERE user_id = users.id
          AND (provider = users.email_provider OR (provider IS NULL AND users.email_provider IS NULL))
        )
        AND id BETWEEN #{start_id} AND #{end_id}
      EOF
    end
  end

  def down
    UserSyncedAttributesMetadata.each_batch do |batch|
      start_id, end_id = batch.pluck('MIN(id), MAX(id)').first

      execute <<-EOF
        UPDATE users
        SET users.email_provider = metadata.provider, users.external_email = metadata.email_synced
        FROM user_synced_attributes_metadata as metadata, users
        WHERE metadata.email_synced = TRUE
        AND metadata.user_id = users.id
        AND id BETWEEN #{start_id} AND #{end_id}
      EOF
    end
  end
end
