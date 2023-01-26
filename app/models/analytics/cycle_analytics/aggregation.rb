# frozen_string_literal: true

class Analytics::CycleAnalytics::Aggregation < ApplicationRecord
  include FromUnion
  include Analytics::CycleAnalytics::Parentable

  validates :incremental_runtimes_in_seconds, :incremental_processed_records, :full_runtimes_in_seconds, :full_processed_records, presence: true, length: { maximum: 10 }, allow_blank: true

  scope :priority_order, ->(column_to_sort = :last_incremental_run_at) { order(arel_table[column_to_sort].asc.nulls_first) }
  scope :enabled, -> { where('enabled IS TRUE') }

  def cursor_for(mode, model)
    {
      updated_at: self["last_#{mode}_#{model.table_name}_updated_at"],
      id: self["last_#{mode}_#{model.table_name}_id"]
    }.compact
  end

  def consistency_check_cursor_for(model)
    {
      :start_event_timestamp => self["last_consistency_check_#{model.issuable_model.table_name}_start_event_timestamp"],
      :end_event_timestamp => self["last_consistency_check_#{model.issuable_model.table_name}_end_event_timestamp"],
      model.issuable_id_column => self["last_consistency_check_#{model.issuable_model.table_name}_issuable_id"]
    }.compact
  end

  def refresh_last_run(mode)
    self["last_#{mode}_run_at"] = Time.current
  end

  def reset_full_run_cursors
    self.last_full_issues_id = nil
    self.last_full_issues_updated_at = nil
    self.last_full_merge_requests_id = nil
    self.last_full_merge_requests_updated_at = nil
  end

  def set_cursor(mode, model, cursor)
    self["last_#{mode}_#{model.table_name}_id"] = cursor[:id]
    self["last_#{mode}_#{model.table_name}_updated_at"] = cursor[:updated_at]
  end

  def set_stats(mode, runtime, processed_records)
    # We only store the last 10 data points
    self["#{mode}_runtimes_in_seconds"] = (self["#{mode}_runtimes_in_seconds"] + [runtime]).last(10)
    self["#{mode}_processed_records"] = (self["#{mode}_processed_records"] + [processed_records]).last(10)
  end

  def estimated_next_run_at
    return unless enabled
    return if last_incremental_run_at.nil?

    estimation = duration_until_the_next_aggregation_job +
      average_aggregation_duration +
      (last_incremental_run_at - earliest_last_run_at)

    estimation < 1 ? nil : estimation.from_now
  end

  def self.safe_create_for_namespace(group_or_project_namespace)
    # Namespaces::ProjectNamespace has no root_ancestor
    # Related: https://gitlab.com/gitlab-org/gitlab/-/issues/386124
    group = group_or_project_namespace.is_a?(Group) ? group_or_project_namespace : group_or_project_namespace.parent
    top_level_group = group.root_ancestor
    aggregation = find_by(group_id: top_level_group.id)
    return aggregation if aggregation&.enabled?

    # At this point we're sure that the group is licensed, we can always enable the aggregation.
    # This re-enables the aggregation in case the group downgraded and later upgraded the license.
    upsert({ group_id: top_level_group.id, enabled: true })

    find(top_level_group.id)
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

  def self.load_batch(last_run_at, column_to_query = :last_incremental_run_at, batch_size = 100)
    last_run_at_not_set = Analytics::CycleAnalytics::Aggregation
      .enabled
      .where(column_to_query => nil)
      .priority_order(column_to_query)
      .limit(batch_size)

    last_run_at_before = Analytics::CycleAnalytics::Aggregation
      .enabled
      .where(arel_table[column_to_query].lt(last_run_at))
      .priority_order(column_to_query)
      .limit(batch_size)

    Analytics::CycleAnalytics::Aggregation
      .from_union([last_run_at_not_set, last_run_at_before], remove_order: false, remove_duplicates: false)
      .limit(batch_size)
  end
end
