# frozen_string_literal: true

class CreateAnalyticsDevopsAdoptionSegments < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    create_table :analytics_devops_adoption_segments, if_not_exists: true do |t|
      t.text :name, null: false, index: { unique: true }
      t.datetime_with_timezone :last_recorded_at

      t.timestamps_with_timezone
    end

    add_text_limit :analytics_devops_adoption_segments, :name, 255
  end

  def down
    drop_table :analytics_devops_adoption_segments
  end
end
