# frozen_string_literal: true

class EnableProjectStudioForTeamMembers < Gitlab::Database::Migration[2.3]
  milestone '18.5'
  restrict_gitlab_migration gitlab_schema: :gitlab_main
  disable_ddl_transaction!

  BATCH_SIZE = 100
  MINIMAL_ACCESS = 5

  class Namespace < MigrationRecord
    self.table_name = :namespaces
    self.inheritance_column = :_type_disabled
  end

  class Member < MigrationRecord
    self.table_name = :members
  end

  class UserPreference < MigrationRecord
    self.table_name = :user_preferences
  end

  def up
    return unless ::Gitlab.com?

    group = Namespace.where(type: 'Group', parent_id: nil).find_by(path: 'gitlab-com')
    return unless group

    ids = Member.where(
      type: 'GroupMember', source_id: group.id, source_type: 'Namespace', requested_at: nil
    ).where('access_level > ?', MINIMAL_ACCESS).pluck(:user_id).to_set

    return if ids.empty?

    ids.each_slice(BATCH_SIZE) do |user_ids|
      UserPreference.where(user_id: user_ids).update_all(project_studio_enabled: true)
    end
  end

  def down
    # no-op
  end
end
