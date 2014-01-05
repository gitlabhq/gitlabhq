# == Schema Information
#
# Table name: services
#
#  id          :integer          not null, primary key
#  type        :string(255)
#  title       :string(255)
#  token       :string(255)
#  project_id  :integer          not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  active      :boolean          default(FALSE), not null
#  project_url :string(255)
#  subdomain   :string(255)
#  room        :string(255)
#

require "flowdock-git-hook"

class FlowdockService < Service
  validates :token, presence: true, if: :activated?

  def title
    'Flowdock'
  end

  def description
    'Flowdock is a collaboration web app for technical teams.'
  end

  def to_param
    'flowdock'
  end

  def fields
    [
      { type: 'text', name: 'token',     placeholder: '' }
    ]
  end

  def execute(push_data)
    repo_path = File.join(Gitlab.config.gitlab_shell.repos_path, "#{project.path_with_namespace}.git")
    Flowdock::Git.post(
      push_data[:ref],
      push_data[:before],
      push_data[:after],
      token: token,
      repo: repo_path,
      repo_url: "#{Gitlab.config.gitlab.url}/#{project.path_with_namespace}",
      commit_url: "#{Gitlab.config.gitlab.url}/#{project.path_with_namespace}/commit/%s",
      diff_url: "#{Gitlab.config.gitlab.url}/#{project.path_with_namespace}/compare/%s...%s",
      )
  end
end
