# frozen_string_literal: true

class RemoveOrphanedLabelLinks < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  class LabelLinks < ActiveRecord::Base
    self.table_name = 'label_links'
    include EachBatch

    def self.orphaned
      where('NOT EXISTS ( SELECT 1 FROM labels WHERE labels.id = label_links.label_id )')
    end
  end

  def up
    # Some of these queries can take up to 10 seconds to run on GitLab.com,
    # which is pretty close to our 15 second statement timeout. To ensure a
    # smooth deployment procedure we disable the statement timeouts for this
    # migration, just in case.
    disable_statement_timeout do
      # On GitLab.com there are over 2,000,000 orphaned label links. On
      # staging, removing 100,000 rows generated a max replication lag of 6.7
      # MB. In total, removing all these rows will only generate about 136 MB
      # of data, so it should be safe to do this.
      LabelLinks.orphaned.each_batch(of: 100_000) do |batch|
        batch.delete_all
      end
    end

    add_concurrent_foreign_key(:label_links, :labels, column: :label_id, on_delete: :cascade)
  end

  def down
    # There is no way to restore orphaned label links.
    if foreign_key_exists?(:label_links, column: :label_id)
      remove_foreign_key(:label_links, column: :label_id)
    end
  end
end
