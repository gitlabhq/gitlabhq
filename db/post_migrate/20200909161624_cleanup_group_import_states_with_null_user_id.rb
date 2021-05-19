# frozen_string_literal: true

class CleanupGroupImportStatesWithNullUserId < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  # With BATCH_SIZE=1000 and group_import_states.count=600 on GitLab.com
  # - 1 iteration will be run
  # - each batch requires on average ~2500ms
  # - 600 rows require on average ~1500ms
  # Expected total run time: ~2500ms
  BATCH_SIZE = 1000

  disable_ddl_transaction!

  class User < ActiveRecord::Base
    self.table_name = 'users'
  end

  class Namespace < ActiveRecord::Base
    self.table_name = 'namespaces'

    belongs_to :owner, class_name: 'CleanupGroupImportStatesWithNullUserId::User'
  end

  class Member < ActiveRecord::Base
    self.table_name = 'members'
    self.inheritance_column = :_type_disabled

    belongs_to :user, class_name: 'CleanupGroupImportStatesWithNullUserId::User'
  end

  class Group < Namespace
    OWNER = 50

    self.inheritance_column = :_type_disabled

    def default_owner
      owners.first || parent&.default_owner || owner
    end

    def parent
      Group.find_by_id(parent_id)
    end

    def owners
      Member.where(type: 'GroupMember', source_type: 'Namespace', source_id: id, requested_at: nil, access_level: OWNER).map(&:user)
    end
  end

  class GroupImportState < ActiveRecord::Base
    include ::EachBatch

    self.table_name = 'group_import_states'

    belongs_to :group, class_name: 'CleanupGroupImportStatesWithNullUserId::Group'
    belongs_to :user, class_name: 'CleanupGroupImportStatesWithNullUserId::User'
  end

  def up
    User.reset_column_information
    Namespace.reset_column_information
    Member.reset_column_information
    Group.reset_column_information
    GroupImportState.reset_column_information

    GroupImportState.each_batch(of: BATCH_SIZE) do |batch|
      batch.each do |group_import_state|
        owner_id = Group.find_by_id(group_import_state.group_id)&.default_owner&.id

        group_import_state.update!(user_id: owner_id) if owner_id
      end
    end

    GroupImportState.where(user_id: nil).delete_all
  end

  def down
    # no-op : can't go back to `NULL` without first dropping the `NOT NULL` constraint
  end
end
