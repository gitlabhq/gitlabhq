class ProjectBadge < Badge
  belongs_to :project

  validates :project, presence: true

  def rendered_link_url(project = nil)
    project ||= self.project
    super
  end

  def rendered_image_url(project = nil)
    project ||= self.project
    super
  end
end
