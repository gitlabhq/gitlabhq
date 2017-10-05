# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class ScheduleCreateGpgKeySubkeysFromGpgKeys < ActiveRecord::Migration
  disable_ddl_transaction!

  DOWNTIME = false

  class GpgKey < ActiveRecord::Base
    self.table_name = 'gpg_keys'
  end

  def up
    GpgKey.select(:id).in_batches do |relation|
      jobs = relation.pluck(:id).map do |id|
        ['CreateGpgKeySubkeysFromGpgKeys', [id]]
      end

      BackgroundMigrationWorker.perform_bulk(jobs)
    end
  end

  def down
  end
end
