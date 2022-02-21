# frozen_string_literal: true
class Analytics::CycleAnalytics::Aggregation < ApplicationRecord
  belongs_to :group, optional: false

  validates :incremental_runtimes_in_seconds, :incremental_processed_records, :last_full_run_runtimes_in_seconds, :last_full_run_processed_records, presence: true, length: { maximum: 10 }

  def self.safe_create_for_group(group)
    top_level_group = group.root_ancestor
    return if Analytics::CycleAnalytics::Aggregation.exists?(group_id: top_level_group.id)

    insert({ group_id: top_level_group.id }, unique_by: :group_id)
  end
end
