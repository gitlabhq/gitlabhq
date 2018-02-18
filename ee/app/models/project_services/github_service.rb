class GithubService < Service
  include Gitlab::Routing
  include ActionView::Helpers::UrlHelper

  prop_accessor :token, :api_url, :owner, :repository_name

  validates :token, presence: true, if: :activated?
  validates :api_url, url: true, allow_blank: true
  validates :owner, presence: true, if: :activated?
  validates :repository_name, presence: true, if: :activated?

  default_value_for :pipeline_events, true

  def title
    'GitHub'
  end

  def description
    "See pipeline statuses on GitHub for your commits and pull requests"
  end

  def detailed_description
    mirror_path = project_settings_repository_path(project)
    mirror_link = link_to('mirroring your GitHub repository', mirror_path)
    "This requires #{mirror_link} to this project.".html_safe
  end

  def self.to_param
    'github'
  end

  def fields
    [
      { type: 'text', name: "token", required: true, placeholder: "e.g. 8d3f016698e...", help: 'Create a <a href="https://github.com/settings/tokens">personal access token</a> with  <code>repo:status</code> access granted and paste it here.'.html_safe },
      { type: 'text', name: "owner", required: true, help: 'The username or organization where the GitHub repository belongs. This can be found in the repository URL: https://github.com/<strong>owner</strong>/repository'.html_safe },
      { type: 'text', name: "repository_name", required: true, help: 'This can be found in the repository URL: https://github.com/owner/<strong>repository</strong>'.html_safe },
      { type: 'text', name: "api_url", placeholder: "https://api.github.com", help: 'Leave blank when using GitHub.com or use <code>https://YOUR-HOSTNAME/api/v3/</code> for GitHub Enterprise'.html_safe }
    ]
  end

  def self.supported_events
    %w(pipeline)
  end
end
