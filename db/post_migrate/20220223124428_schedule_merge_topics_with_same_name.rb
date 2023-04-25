# frozen_string_literal: true

class ScheduleMergeTopicsWithSameName < Gitlab::Database::Migration[1.0]
  MIGRATION = 'MergeTopicsWithSameName'
  BATCH_SIZE = 100

  disable_ddl_transaction!

  class Topic < ActiveRecord::Base
    self.table_name = 'topics'
  end

  def up
    Topic.select('LOWER(name) as name').group('LOWER(name)').having('COUNT(*) > 1').order('LOWER(name)')
    .in_groups_of(BATCH_SIZE, false).each_with_index do |group, i|
      migrate_in((i + 1) * 2.minutes, MIGRATION, [group.map(&:name)])
    end
  end

  def down
    # no-op
  end
end
