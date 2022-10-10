# frozen_string_literal: true

class AddTextLimitToProjectsJitsuKey < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  def up
    add_text_limit :project_settings, :jitsu_key, 100
  end

  def down
    remove_text_limit :project_settings, :jitsu_key
  end
end
