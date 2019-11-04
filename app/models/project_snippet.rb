# frozen_string_literal: true

class ProjectSnippet < Snippet
  belongs_to :project

  validates :project, presence: true
end
