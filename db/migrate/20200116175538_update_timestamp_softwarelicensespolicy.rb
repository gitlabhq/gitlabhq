# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class UpdateTimestampSoftwarelicensespolicy < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    time = Time.zone.now

    update_column_in_batches(:software_license_policies, :created_at, time) do |table, query|
      query.where(table[:created_at].eq(nil))
    end

    update_column_in_batches(:software_license_policies, :updated_at, time) do |table, query|
      query.where(table[:updated_at].eq(nil))
    end
  end

  def down
    # no-op
  end
end
