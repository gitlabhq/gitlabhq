class CreateUserPreferences < ActiveRecord::Migration
  DOWNTIME = false

  class UserPreference < ActiveRecord::Base
    self.table_name = 'user_preferences'

    DISCUSSION_FILTERS = { all_activity: 0, comments: 1 }.freeze
  end

  def change
    create_table :user_preferences do |t|
      t.references :user,
                   null: false,
                   index: { unique: true }, foreign_key: { on_delete: :cascade }

      t.integer :issue_discussion_filter, index: true,
        default: UserPreference::DISCUSSION_FILTERS[:all_activity],
        null: false, limit: 2

      t.integer :merge_request_discussion_filter, index: true,
        default: UserPreference::DISCUSSION_FILTERS[:all_activity],
        null: false, limit: 2

      t.timestamps_with_timezone null: false
    end
  end
end
