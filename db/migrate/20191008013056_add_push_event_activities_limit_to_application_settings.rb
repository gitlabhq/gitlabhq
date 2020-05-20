# frozen_string_literal: true

class AddPushEventActivitiesLimitToApplicationSettings < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default(:application_settings, :push_event_activities_limit, :integer, default: 3) # rubocop:disable Migration/AddColumnWithDefault
  end

  def down
    remove_column(:application_settings, :push_event_activities_limit)
  end
end
