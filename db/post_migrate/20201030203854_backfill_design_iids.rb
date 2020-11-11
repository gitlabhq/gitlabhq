# frozen_string_literal: true

class BackfillDesignIids < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  class Designs < ActiveRecord::Base
    include EachBatch

    self.table_name = 'design_management_designs'
  end

  def up
    backfill = ::Gitlab::BackgroundMigration::BackfillDesignInternalIds.new(Designs)

    Designs.select(:project_id).distinct.each_batch(of: 100, column: :project_id) do |relation|
      backfill.perform(relation)
    end
  end

  def down
    # NOOP
  end
end
