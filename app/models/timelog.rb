# frozen_string_literal: true

class Timelog < ApplicationRecord
  include Importable
  include Sortable
  include EachBatch

  # Gitlab::TimeTrackingFormatter.parse("4y")
  # Approx. 4 years * 365.25 days/y * 24 hours/d * 60 minutes/h * 60 seconds/m
  # We need to stay below 2^31 seconds here to avoid IntegerEncodingError in GraphQL:
  # https://gitlab.com/gitlab-org/gitlab/-/work_items/418226
  MAX_TOTAL_TIME_SPENT = 126230400

  before_validation :ensure_namespace_id
  before_save :set_project

  validates :time_spent, :user, :namespace, presence: true
  validates :summary, length: { maximum: 255 }
  validates_with ExactlyOnePresentValidator, fields: [:issue, :merge_request]
  validate :check_total_time_spent_is_within_range, on: :create, unless: :importing?, if: :time_spent

  belongs_to :issue, touch: true
  belongs_to :merge_request, touch: true
  belongs_to :project
  belongs_to :user
  belongs_to :note
  belongs_to :timelog_category, optional: true, class_name: 'TimeTracking::TimelogCategory'
  belongs_to :namespace

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

  scope :with_summary, ->(summary) do
    where(summary: summary)
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
    errors.add(:base, _("Total time spent cannot exceed 4 years.")) if total_time_spent > MAX_TOTAL_TIME_SPENT
  end

  def set_project
    self.project_id = issuable.project_id
  end

  def ensure_namespace_id
    self.namespace_id = if merge_request.present?
                          merge_request.project&.project_namespace_id
                        elsif issue.present?
                          issue.namespace_id
                        end
  end
end
