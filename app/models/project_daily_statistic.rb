# frozen_string_literal: true

class ProjectDailyStatistic < ApplicationRecord
  include CounterAttribute

  belongs_to :project

  counter_attribute :fetch_count

  scope :of_project, ->(project) { where(project: project) }
  scope :of_last_30_days, -> { where('date >= ?', 29.days.ago.utc.to_date) }
  scope :sorted_by_date_desc, -> { order(project_id: :desc, date: :desc) }
  scope :sum_fetch_count, -> { sum(:fetch_count) }

  def self.find_or_create_project_daily_statistic(project_id, date)
    daily_statistic = find_by(project_id: project_id, date: date)
    return daily_statistic if daily_statistic

    result = upsert(
      { project_id: project_id, date: date, fetch_count: 0 },
      unique_by: [:project_id, :date],
      on_duplicate: :skip
    )

    statistic_id = result&.rows&.first&.first
    if statistic_id
      find_by_id(statistic_id)
    else
      find_by!(project_id: project_id, date: date)
    end
  end
end
