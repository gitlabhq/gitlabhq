# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class CleanUpForMembers < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  disable_ddl_transaction!

  class Member < ActiveRecord::Base
    include EachBatch

    self.table_name = 'members'
  end

  def up
    condition = <<~EOF.squish
      invite_token IS NULL AND
      NOT EXISTS (SELECT 1 FROM users WHERE users.id = members.user_id)
    EOF

    Member.each_batch(of: 10_000) do |batch|
      batch.where(condition).delete_all
    end
  end

  def down
  end
end
