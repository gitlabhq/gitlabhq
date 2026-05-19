# frozen_string_literal: true

class CleanupSecretsManagersAndRotationInfos < Gitlab::Database::Migration[2.3]
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org
  disable_ddl_transaction!

  milestone '19.0'

  def up
    execute('DELETE FROM project_secrets_managers')
    execute('DELETE FROM group_secrets_managers')
    execute('DELETE FROM secret_rotation_infos')
    execute('DELETE FROM group_secret_rotation_infos')
  end

  def down
    # no-op: closed-beta data cannot be restored
  end
end
