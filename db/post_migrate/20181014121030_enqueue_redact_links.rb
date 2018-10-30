# frozen_string_literal: true

class EnqueueRedactLinks < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  BATCH_SIZE = 1000
  DELAY_INTERVAL = 5.minutes.to_i
  MIGRATION = 'RedactLinks'

  disable_ddl_transaction!

  class Note < ActiveRecord::Base
    include EachBatch

    self.table_name = 'notes'
    self.inheritance_column = :_type_disabled
  end

  class Issue < ActiveRecord::Base
    include EachBatch

    self.table_name = 'issues'
    self.inheritance_column = :_type_disabled
  end

  class MergeRequest < ActiveRecord::Base
    include EachBatch

    self.table_name = 'merge_requests'
    self.inheritance_column = :_type_disabled
  end

  class Snippet < ActiveRecord::Base
    include EachBatch

    self.table_name = 'snippets'
    self.inheritance_column = :_type_disabled
  end

  def up
    disable_statement_timeout do
      schedule_migration(Note, 'note')
      schedule_migration(Issue, 'description')
      schedule_migration(MergeRequest, 'description')
      schedule_migration(Snippet, 'description')
    end
  end

  def down
    # nothing to do
  end

  private

  def schedule_migration(model, field)
    link_pattern = "%/sent_notifications/" + ("_" * 32) + "/unsubscribe%"

    model.where("#{field} like ?", link_pattern).each_batch(of: BATCH_SIZE) do |batch, index|
      start_id, stop_id = batch.pluck('MIN(id)', 'MAX(id)').first

      BackgroundMigrationWorker.perform_in(index * DELAY_INTERVAL, MIGRATION, [model.name.demodulize, field, start_id, stop_id])
    end
  end
end
