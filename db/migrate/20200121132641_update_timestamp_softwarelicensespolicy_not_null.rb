# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class UpdateTimestampSoftwarelicensespolicyNotNull < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    change_column_null(:software_license_policies, :created_at, false)
    change_column_null(:software_license_policies, :updated_at, false)
  end
end
