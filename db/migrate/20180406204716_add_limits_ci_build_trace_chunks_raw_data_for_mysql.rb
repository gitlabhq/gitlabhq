# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.
require Rails.root.join('db/migrate/limits_ci_build_trace_chunks_raw_data_for_mysql')

class AddLimitsCiBuildTraceChunksRawDataForMysql < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    LimitsCiBuildTraceChunksRawDataForMysql.new.up
  end
end
