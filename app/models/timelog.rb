# frozen_string_literal: true

class Timelog < ApplicationRecord
  include Importable

  before_save :set_project

  validates :time_spent, :user, presence: true
  validates :summary, length: { maximum: 255 }
  validate :issuable_id_is_present, unless: :importing?

  belongs_to :issue, touch: true
  belongs_to :merge_request, touch: true
  belongs_to :project
  belongs_to :user
  belongs_to :note

  scope :in_group, -> (group) do
    joins(:project).where(projects: { namespace: group.self_and_descendants })
  end

  scope :at_or_after, -> (start_time) do
    where('spent_at >= ?', start_time)
  end

  scope :at_or_before, -> (end_time) do
    where('spent_at <= ?', end_time)
  end

  def issuable
    issue || merge_request
  end

  private

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
