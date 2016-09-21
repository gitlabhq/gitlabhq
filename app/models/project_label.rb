class ProjectLabel < Label
  belongs_to :project

  validates :project, presence: true

  validate :title_must_not_exist_at_group_level

  delegate :group, to: :project, allow_nil: true

  private

  def title_must_not_exist_at_group_level
    return unless group.present?

    if group.labels.with_title(self.title).exists?
      errors.add(:title, :label_already_exists_at_group_level, group: group.name)
    end
  end
end
