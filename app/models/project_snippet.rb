# frozen_string_literal: true

class ProjectSnippet < Snippet
  belongs_to :project

  validates :project, presence: true
  validates :secret, inclusion: { in: [false] }

  def web_url(only_path: nil)
    Gitlab::Routing.url_helpers.project_snippet_url(project, self, only_path: only_path)
  end
end
