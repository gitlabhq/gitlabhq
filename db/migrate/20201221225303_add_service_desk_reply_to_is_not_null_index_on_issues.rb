# frozen_string_literal: true

class AddServiceDeskReplyToIsNotNullIndexOnIssues < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    # no-op, the migration's version number was lowered to be executed earlier than db/post_migrate/20201128210234_schedule_populate_issue_email_participants.rb
    #
    # The new migration is located here: db/migrate/20201128210000_add_service_desk_reply_to_is_not_null_index_on_issues_fix.rb
  end
end
