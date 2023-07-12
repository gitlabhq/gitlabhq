# frozen_string_literal: true

class ChangeProjectViewDefault < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def change
    change_column_default(:users, :project_view, from: 0, to: 2)
  end
end
