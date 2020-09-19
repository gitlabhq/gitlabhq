# frozen_string_literal: true

class ProductAnalyticsEvent < ApplicationRecord
  self.table_name = 'product_analytics_events_experimental'

  # Ignore that the partition key :project_id is part of the formal primary key
  self.primary_key = :id

  belongs_to :project

  validates :event_id, :project_id, :v_collector, :v_etl, presence: true

  # There is no default Rails timestamps in the table.
  # collector_tstamp is a timestamp when a collector recorded an event.
  scope :order_by_time, -> { order(collector_tstamp: :desc) }

  # If we decide to change this scope to use date_trunc('day', collector_tstamp),
  # we should remember that a btree index on collector_tstamp will be no longer effective.
  scope :timerange, ->(duration, today = Time.zone.today) {
    where('collector_tstamp BETWEEN ? AND ? ', today - duration + 1, today + 1)
  }

  scope :by_category_and_action, ->(category, action) { where(se_category: category, se_action: action) }

  def self.count_by_graph(graph, days)
    group(graph).timerange(days).count
  end

  def self.count_collector_tstamp_by_day(days)
    group("DATE_TRUNC('day', collector_tstamp)")
      .reorder('date_trunc_day_collector_tstamp')
      .timerange(days)
      .count
  end

  def as_json_wo_empty
    as_json.compact
  end
end
