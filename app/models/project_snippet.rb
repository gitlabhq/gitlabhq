# frozen_string_literal: true

class ProjectSnippet < Snippet
  belongs_to :project

  validates :project, presence: true
  validates :secret, inclusion: { in: [false] }

  scope :by_project, ->(project) { where(project: project) }
end
