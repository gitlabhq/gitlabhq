# frozen_string_literal: true

class AddProjectShowDefaultAwardEmojis < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :project_settings, :show_default_award_emojis, :boolean, default: true, null: false
  end
end
