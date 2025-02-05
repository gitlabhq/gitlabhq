# frozen_string_literal: true

class RemoveDuplicateUserMemberRoles < Gitlab::Database::Migration[2.2]
  restrict_gitlab_migration gitlab_schema: :gitlab_main
  milestone '17.9'

  def up
    # Remove duplicates keeping only the record with the minimum id for each user_id
    execute <<-SQL
      DELETE FROM user_member_roles
      USING (
        SELECT user_id, MIN(id) as min_id
        FROM user_member_roles
        GROUP BY user_id
        HAVING COUNT(id) > 1
      ) as user_member_roles_duplicates
      WHERE user_member_roles_duplicates.user_id = user_member_roles.user_id
      AND user_member_roles_duplicates.min_id <> user_member_roles.id
    SQL
  end

  def down
    # This migration cannot be reversed as it removes data
  end
end
