# frozen_string_literal: true

class ProjectBadge < Badge
  include EachBatch

  self.allow_legacy_sti_class = true

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
