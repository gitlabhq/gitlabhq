# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class ScheduleCreateGpgKeySubkeysFromGpgKeys < ActiveRecord::Migration
  disable_ddl_transaction!

  DOWNTIME = false
  MIGRATION = 'CreateGpgKeySubkeysFromGpgKeys'

  class GpgKey < ActiveRecord::Base
    self.table_name = 'gpg_keys'

    include EachBatch
  end

  def up
    GpgKey.select(:id).each_batch do |gpg_keys|
      jobs = gpg_keys.pluck(:id).map do |id|
        [MIGRATION, [id]]
      end

      BackgroundMigrationWorker.bulk_perform_async(jobs)
    end
  end

  def down
  end
end
