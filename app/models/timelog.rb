# frozen_string_literal: true

class Timelog < ApplicationRecord
  # Gitlab::TimeTrackingFormatter.parse("1y") == 31557600 seconds
  # 31557600 slightly deviates from (365 days * 24 hours/day * 60 minutes/hour * 60 seconds/minute)
  MAX_TOTAL_TIME_SPENT = 31557600.seconds.to_i # a year

  include Importable
  include Sortable
  include EachBatch

  before_save :set_project

  validates :time_spent, :user, presence: true
  validates :summary, length: { maximum: 255 }
  validate :issuable_id_is_present, unless: :importing?
  validate :check_total_time_spent_is_within_range, on: :create, unless: :importing?, if: :time_spent

  belongs_to :issue, touch: true
  belongs_to :merge_request, touch: true
  belongs_to :project
  belongs_to :user
  belongs_to :note
  belongs_to :timelog_category, optional: true, class_name: 'TimeTracking::TimelogCategory'

  scope :in_group, ->(group) do
    joins(:project).where(projects: { namespace: group.self_and_descendants })
  end

  scope :in_project, ->(project) do
    where(project: project)
  end

  scope :for_user, ->(user) do
    where(user: user)
  end

  scope :at_or_after, ->(start_time) do
    where('spent_at >= ?', start_time)
  end

  scope :at_or_before, ->(end_time) do
    where('spent_at <= ?', end_time)
  end

  scope :order_scope_asc, ->(field) { order(arel_table[field].asc.nulls_last) }
  scope :order_scope_desc, ->(field) { order(arel_table[field].desc.nulls_last) }

  def issuable
    issue || merge_request
  end

  def self.sort_by_field(field)
    case field.to_s
    when 'spent_at_asc' then order_scope_asc(:spent_at)
    when 'spent_at_desc' then order_scope_desc(:spent_at)
    when 'time_spent_asc' then order_scope_asc(:time_spent)
    when 'time_spent_desc' then order_scope_desc(:time_spent)
    else order_by(field)
    end
  end

  private

  def check_total_time_spent_is_within_range
    total_time_spent = issuable.timelogs.sum(:time_spent) + time_spent

    errors.add(:base, _("Total time spent cannot be negative.")) if total_time_spent < 0
    errors.add(:base, _("Total time spent cannot exceed a year.")) if total_time_spent > MAX_TOTAL_TIME_SPENT
  end

  def issuable_id_is_present
    if issue_id && merge_request_id
      errors.add(:base, _('Only Issue ID or merge request ID is required'))
    elsif issuable.nil?
      errors.add(:base, _('Issue or merge request ID is required'))
    end
  end

  def set_project
    self.project_id = issuable.project_id
  end

  # Rails5 defaults to :touch_later, overwrite for normal touch
  def belongs_to_touch_method
    :touch
  end
end
