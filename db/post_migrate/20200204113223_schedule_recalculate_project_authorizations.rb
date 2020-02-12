# frozen_string_literal: true

class ScheduleRecalculateProjectAuthorizations < ActiveRecord::Migration[5.1]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  MIGRATION = 'RecalculateProjectAuthorizations'
  BATCH_SIZE = 2_500
  DELAY_INTERVAL = 2.minutes.to_i

  disable_ddl_transaction!

  class Namespace < ActiveRecord::Base
    include ::EachBatch

    self.table_name = 'namespaces'
  end

  class ProjectAuthorization < ActiveRecord::Base
    include ::EachBatch

    self.table_name = 'project_authorizations'
  end

  def up
    say "Scheduling #{MIGRATION} jobs"

    max_group_id = Namespace.where(type: 'Group').maximum(:id)
    project_authorizations = ProjectAuthorization.where('project_id <= ?', max_group_id)
                                                 .select(:user_id)
                                                 .distinct

    project_authorizations.each_batch(of: BATCH_SIZE, column: :user_id) do |authorizations, index|
      delay = index * DELAY_INTERVAL
      user_ids = authorizations.map(&:user_id)
      BackgroundMigrationWorker.perform_in(delay, MIGRATION, [user_ids])
    end
  end

  def down
  end
end
