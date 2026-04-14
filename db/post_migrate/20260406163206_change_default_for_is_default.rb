# frozen_string_literal: true

class ChangeDefaultForIsDefault < Gitlab::Database::Migration[2.3]
  milestone '18.11'

  def change
    change_column_default('security_project_tracked_contexts', 'is_default', from: false, to: nil)
  end
end
