# frozen_string_literal: true

# rubocop:disable Migration/AddLimitToTextColumns
# limit is added in 20220914131449_add_text_limit_to_projects_jitsu_key.rb
class AddJitsuKeyToProjects < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  def up
    with_lock_retries do
      add_column :project_settings, :jitsu_key, :text
    end
  end

  def down
    with_lock_retries do
      remove_column :project_settings, :jitsu_key
    end
  end
end
# rubocop:enable Migration/AddLimitToTextColumns
