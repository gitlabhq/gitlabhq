# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddStateIdDefaultValue < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    change_column_default :issues, :state_id, 1
    change_column_null :issues, :state_id, false
    change_column_default :merge_requests, :state_id, 1
    change_column_null :merge_requests, :state_id, false
  end

  def down
    change_column_default :issues, :state_id, nil
    change_column_null :issues, :state_id, true
    change_column_default :merge_requests, :state_id, nil
    change_column_null :merge_requests, :state_id, true
  end
end
