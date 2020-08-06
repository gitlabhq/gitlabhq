# frozen_string_literal: true

class BackfillDesignsRelativePosition < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INTERVAL = 2.minutes
  BATCH_SIZE = 1000
  MIGRATION = 'BackfillDesignsRelativePosition'

  disable_ddl_transaction!

  class Issue < ActiveRecord::Base
    include EachBatch

    self.table_name = 'issues'

    has_many :designs
  end

  class Design < ActiveRecord::Base
    self.table_name = 'design_management_designs'
  end

  def up
    issues_with_designs = Issue.where(id: Design.select(:issue_id))

    issues_with_designs.each_batch(of: BATCH_SIZE) do |relation, index|
      issue_ids = relation.pluck(:id)
      delay = INTERVAL * index

      migrate_in(delay, MIGRATION, [issue_ids])
    end
  end

  def down
  end
end
