class CreateUserPreferences < ActiveRecord::Migration
  DOWNTIME = false

  class UserPreference < ActiveRecord::Base
    self.table_name = 'user_preferences'

    DISCUSSION_FILTERS = { all_activity: 0, comments: 1 }.freeze
  end

  def change
    create_table :user_preferences do |t|
      t.timestamps_with_timezone null: false

      t.integer :issue_discussion_filter, index: true,
        default: UserPreference::DISCUSSION_FILTERS[:all_activity],
        null: false

      t.integer :merge_request_discussion_filter, index: true,
        default: UserPreference::DISCUSSION_FILTERS[:all_activity],
        null: false
    end
  end
end
