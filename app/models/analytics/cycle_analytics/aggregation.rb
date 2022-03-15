# frozen_string_literal: true

class Analytics::CycleAnalytics::Aggregation < ApplicationRecord
  include FromUnion

  belongs_to :group, optional: false

  validates :incremental_runtimes_in_seconds, :incremental_processed_records, :last_full_run_runtimes_in_seconds, :last_full_run_processed_records, presence: true, length: { maximum: 10 }, allow_blank: true

  scope :priority_order, -> { order('last_incremental_run_at ASC NULLS FIRST') }
  scope :enabled, -> { where('enabled IS TRUE') }

  def estimated_next_run_at
    return unless enabled
    return if last_incremental_run_at.nil?

    estimation = duration_until_the_next_aggregation_job +
      average_aggregation_duration +
      (last_incremental_run_at - earliest_last_run_at)

    estimation < 1 ? nil : estimation.from_now
  end

  def self.safe_create_for_group(group)
    top_level_group = group.root_ancestor
    aggregation = find_by(group_id: top_level_group.id)
    return aggregation if aggregation.present?

    insert({ group_id: top_level_group.id }, unique_by: :group_id)
    find_by(group_id: top_level_group.id)
  end

  private

  # The aggregation job is scheduled every 10 minutes: */10 * * * *
  def duration_until_the_next_aggregation_job
    (10 - (DateTime.current.minute % 10)).minutes.seconds
  end

  def average_aggregation_duration
    return 0.seconds if incremental_runtimes_in_seconds.empty?

    average = incremental_runtimes_in_seconds.sum.fdiv(incremental_runtimes_in_seconds.size)
    average.seconds
  end

  def earliest_last_run_at
    max = self.class.select(:last_incremental_run_at)
      .where(enabled: true)
      .where.not(last_incremental_run_at: nil)
      .priority_order
      .limit(1)
      .to_sql

    connection.select_value("(#{max})")
  end

  def self.load_batch(last_run_at, batch_size = 100)
    last_run_at_not_set = Analytics::CycleAnalytics::Aggregation
      .enabled
      .where(last_incremental_run_at: nil)
      .priority_order
      .limit(batch_size)

    last_run_at_before = Analytics::CycleAnalytics::Aggregation
      .enabled
      .where('last_incremental_run_at < ?', last_run_at)
      .priority_order
      .limit(batch_size)

    Analytics::CycleAnalytics::Aggregation
      .from_union([last_run_at_not_set, last_run_at_before], remove_order: false, remove_duplicates: false)
      .limit(batch_size)
  end
end
