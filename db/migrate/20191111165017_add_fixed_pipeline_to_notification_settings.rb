# frozen_string_literal: true

class AddFixedPipelineToNotificationSettings < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def change
    add_column :notification_settings, :fixed_pipeline, :boolean
  end
end
