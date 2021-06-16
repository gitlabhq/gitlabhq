# frozen_string_literal: true

class GroupProtectedEnvironmentsAddColumn < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  def up
    add_column :protected_environments, :group_id, :bigint
    change_column_null :protected_environments, :project_id, true
  end

  def down
    change_column_null :protected_environments, :project_id, false
    remove_column :protected_environments, :group_id
  end
end
