class ProjectLabel < Label
  belongs_to :project

  validates :project, presence: true

  validate :title_must_not_exist_at_group_level

  delegate :group, to: :project, allow_nil: true

  ##
  # Returns the String necessary to reference this ProjectLabel in Markdown
  #
  # format - Symbol format to use (default: :id, optional: :name)
  #
  # Examples:
  #
  #   ProjectLabel.first.to_reference                # => "~1"
  #   ProjectLabel.first.to_reference(format: :name) # => "~\"bug\""
  #   ProjectLabel.first.to_reference(project)       # => "gitlab-org/gitlab-ce~1"
  #
  # Returns a String
  #
  def to_reference(from_project = nil, format: :id)
    format_reference = label_format_reference(format)
    reference = "#{self.class.reference_prefix}#{format_reference}"

    if cross_project_reference?(from_project)
      project.to_reference + reference
    else
      reference
    end
  end

  private

  def title_must_not_exist_at_group_level
    return unless group.present?

    if group.labels.with_title(self.title).exists?
      errors.add(:title, :label_already_exists_at_group_level, group: group.name)
    end
  end
end
