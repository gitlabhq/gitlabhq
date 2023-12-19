# frozen_string_literal: true

class DropIdxProjectsOnIdServiceDeskEnabledForGitlabCom < Gitlab::Database::Migration[2.2]
  milestone '16.7'

  disable_ddl_transaction!

  TABLE_NAME = :projects
  INDEX_NAME = :index_projects_on_id_service_desk_enabled

  def up
    return unless should_run?

    remove_concurrent_index_by_name TABLE_NAME, INDEX_NAME
  end

  def down
    return unless should_run?

    add_concurrent_index TABLE_NAME, :id, where: 'service_desk_enabled = true', name: INDEX_NAME
  end

  private

  def should_run?
    Gitlab.com_except_jh?
  end
end
