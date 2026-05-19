# frozen_string_literal: true

# Reorder organization states so that unconfirmed=0 (the database default),
# avoiding the need to change the column default. Only the active state (0)
# needs to be updated since deletion_scheduled (1) and deletion_in_progress (2)
# remain unchanged.
#
# New mapping: unconfirmed: 0, deletion_scheduled: 1, deletion_in_progress: 2,
#              confirmed: 3, active: 4
# Old mapping: active: 0, deletion_scheduled: 1, deletion_in_progress: 2
class ChangeOrganizationsStateDefaultToUnconfirmed < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  def up
    # Move active (0) to 4; deletion_scheduled (1) and deletion_in_progress (2) are unchanged
    execute("UPDATE organizations SET state = 4 WHERE state = 0")
  end

  def down
    # Reverse: update active records back to 0
    execute("UPDATE organizations SET state = 0 WHERE state = 4")
  end
end
