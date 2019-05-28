# frozen_string_literal: true

class ProjectDailyStatistic < ApplicationRecord
  belongs_to :project

  scope :of_project, -> (project) { where(project: project) }
  scope :of_last_30_days, -> { where('date >= ?', 29.days.ago.utc.to_date) }
  scope :sorted_by_date_desc, -> { order(project_id: :desc, date: :desc) }
  scope :sum_fetch_count, -> { sum(:fetch_count) }
end
