# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AssignOrganizationToPlaceholderUsers < Gitlab::Database::Migration[2.3]
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  disable_ddl_transaction!

  milestone '18.1'

  class User < MigrationRecord
    self.table_name = 'users'
  end

  class OrganizationUser < MigrationRecord
    self.table_name = 'organization_users'
  end

  def up
    User
      .select(:id)
      .where(user_type: 15)
      .find_in_batches(batch_size: 100) do |batch|
      records = batch.map do |user|
        current_time = Time.zone.now
        {
          user_id: user.id,
          organization_id: 1,
          created_at: current_time,
          updated_at: current_time
        }
      end

      OrganizationUser.insert_all(records, unique_by: [:organization_id, :user_id])
    end
  end

  def down
    # no-op
  end
end
