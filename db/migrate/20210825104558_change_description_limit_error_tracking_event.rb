# frozen_string_literal: true

class ChangeDescriptionLimitErrorTrackingEvent < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  def up
    remove_text_limit :error_tracking_error_events, :description
    add_text_limit :error_tracking_error_events, :description, 1024
  end

  def down
    remove_text_limit :error_tracking_error_events, :description
    add_text_limit :error_tracking_error_events, :description, 255
  end
end
