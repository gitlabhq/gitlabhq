# frozen_string_literal: true

class ProjectLabel < Label
  MAX_NUMBER_OF_PRIORITIES = 1

  self.allow_legacy_sti_class = true

  belongs_to :project
  belongs_to :parent_container, foreign_key: :project_id, class_name: 'Project'

  validates :project, presence: true

  validate :permitted_numbers_of_priorities
  validate :title_must_not_exist_at_group_level

  delegate :group, to: :project, allow_nil: true

  alias_attribute :subject, :project

  def subject_foreign_key
    'project_id'
  end

  def to_reference(target_container = nil, format: :id, full: false)
    super(project, target_container: target_container, format: format, full: full)
  end

  def preloaded_parent_container
    association(:project).loaded? ? project : parent_container
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
