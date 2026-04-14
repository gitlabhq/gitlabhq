# frozen_string_literal: true

class AddIpAddressToMembersDeletionSchedules < Gitlab::Database::Migration[2.3]
  milestone '18.11'

  def up
    add_column :members_deletion_schedules, :ip_address, :inet, if_not_exists: true
  end

  def down
    remove_column :members_deletion_schedules, :ip_address, if_exists: true
  end
end
