# frozen_string_literal: true

class RemoveNullReleases < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  class Release < ActiveRecord::Base
    include EachBatch

    self.table_name = 'releases'
  end

  def up
    Release.all.each_batch(of: 25000) do |rel|
      rel.where(tag: nil).delete_all
    end
  end

  def down
    # no-op
    #
    # releases with the same tag within a project have been removed
    # and therefore the duplicate release data is no longer available
  end
end
