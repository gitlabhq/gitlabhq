# frozen_string_literal: true

class ProjectLabel < Label
  MAX_NUMBER_OF_PRIORITIES = 1

  belongs_to :project

  validates :project, presence: true

  validate :permitted_numbers_of_priorities
  validate :title_must_not_exist_at_group_level

  delegate :group, to: :project, allow_nil: true

  alias_attribute :subject, :project

  def subject_foreign_key
    'project_id'
  end

  def to_reference(target_project = nil, format: :id, full: false)
    super(project, target_project: target_project, format: format, full: full)
  end

  private

  def title_must_not_exist_at_group_level
    return unless group.present? && title_changed?

    if group.labels.with_title(self.title).exists?
      errors.add(:title, :label_already_exists_at_group_level, group: group.name)
    end
  end

  def permitted_numbers_of_priorities
    if priorities && priorities.size > MAX_NUMBER_OF_PRIORITIES
      errors.add(:priorities, 'Number of permitted priorities exceeded')
    end
  end
end
