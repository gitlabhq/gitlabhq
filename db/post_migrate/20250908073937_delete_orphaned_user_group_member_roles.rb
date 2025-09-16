# frozen_string_literal: true

class DeleteOrphanedUserGroupMemberRoles < Gitlab::Database::Migration[2.3]
  milestone '18.4'
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org
  disable_ddl_transaction!

  BATCH_SIZE = 1_000

  def up
    user_group_member_roles = define_batchable_model('user_group_member_roles')

    user_group_member_roles.where(shared_with_group_id: nil).each_batch(of: BATCH_SIZE) do |batch|
      without_matching_member_ids = find_records_without_matching_member_record(batch)

      next if without_matching_member_ids.empty?

      user_group_member_roles.where(id: without_matching_member_ids).delete_all
    end
  end

  def down
    # no-op
  end

  private

  def find_records_without_matching_member_record(batch)
    batch
      .joins("LEFT JOIN members ON members.user_id = user_group_member_roles.user_id \
        AND members.source_id = user_group_member_roles.group_id \
        AND members.source_type = 'Namespace' \
        AND members.member_role_id = user_group_member_roles.member_role_id")
      .where(members: { id: nil })
      .ids
  end
end
