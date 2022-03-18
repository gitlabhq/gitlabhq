# frozen_string_literal: true

class RemoveDuplicateProjectTagReleases < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  class Release < ActiveRecord::Base
    include EachBatch

    self.table_name = 'releases'
  end

  def up
    Release.each_batch(of: 5000) do |relation|
      relation
        .where('exists (select 1 from releases r2 where r2.project_id = releases.project_id and r2.tag = releases.tag and r2.id > releases.id)')
        .delete_all
    end
  end

  def down
    # no-op
    #
    # releases with the same tag within a project have been removed
    # and therefore the duplicate release data is no longer available
  end
end
