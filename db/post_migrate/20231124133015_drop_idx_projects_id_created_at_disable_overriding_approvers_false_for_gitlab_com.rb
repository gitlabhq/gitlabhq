# frozen_string_literal: true

class DropIdxProjectsIdCreatedAtDisableOverridingApproversFalseForGitlabCom < Gitlab::Database::Migration[2.2]
  milestone '16.7'

  disable_ddl_transaction!

  TABLE_NAME = :projects
  INDEX_NAME = :idx_projects_id_created_at_disable_overriding_approvers_false

  def up
    return unless should_run?

    remove_concurrent_index_by_name TABLE_NAME, INDEX_NAME
  end

  def down
    return unless should_run?

    add_concurrent_index(
      TABLE_NAME,
      [:id, :created_at],
      where: "(disable_overriding_approvers_per_merge_request = FALSE) OR " \
             "(disable_overriding_approvers_per_merge_request IS NULL)",
      name: INDEX_NAME
    )
  end

  private

  def should_run?
    Gitlab.com_except_jh?
  end
end
