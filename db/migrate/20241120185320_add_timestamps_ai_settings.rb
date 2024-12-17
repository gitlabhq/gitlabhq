# frozen_string_literal: true

class AddTimestampsAiSettings < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  def up
    add_timestamps_with_timezone(:ai_settings, default: -> { 'NOW()' })
  end

  def down
    remove_timestamps(:ai_settings)
  end
end
