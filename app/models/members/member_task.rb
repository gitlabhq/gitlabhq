# frozen_string_literal: true

class MemberTask < ApplicationRecord
  TASKS = {
    code: 0,
    ci: 1,
    issues: 2
  }.freeze

  belongs_to :member
  belongs_to :project

  validates :member, :project, presence: true
  validates :tasks, inclusion: { in: TASKS.values }
  validate :tasks_uniqueness
  validate :project_in_member_source

  scope :for_members, -> (members) { joins(:member).where(member: members) }

  def tasks_to_be_done
    Array(self[:tasks]).map { |task| TASKS.key(task) }
  end

  def tasks_to_be_done=(tasks)
    self[:tasks] = Array(tasks).map do |task|
      TASKS[task.to_sym]
    end.uniq
  end

  private

  def tasks_uniqueness
    errors.add(:tasks, 'are not unique') unless Array(tasks).length == Array(tasks).uniq.length
  end

  def project_in_member_source
    case member
    when GroupMember
      errors.add(:project, _('is not in the member group')) unless project.namespace == member.source
    when ProjectMember
      errors.add(:project, _('is not the member project')) unless project == member.source
    end
  end
end
