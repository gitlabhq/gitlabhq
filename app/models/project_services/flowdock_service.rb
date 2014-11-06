# == Schema Information
#
# Table name: services
#
#  id         :integer          not null, primary key
#  type       :string(255)
#  title      :string(255)
#  project_id :integer          not null
#  created_at :datetime
#  updated_at :datetime
#  active     :boolean          default(FALSE), not null
#  properties :text
#

require "flowdock-git-hook"

class FlowdockService < Service
  prop_accessor :token
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
    Flowdock::Git.post(
      push_data[:ref],
      push_data[:before],
      push_data[:after],
      token: token,
      repo: project.repository.path_to_repo,
      repo_url: "#{Gitlab.config.gitlab.url}/#{project.path_with_namespace}",
      commit_url: "#{Gitlab.config.gitlab.url}/#{project.path_with_namespace}/commit/%s",
      diff_url: "#{Gitlab.config.gitlab.url}/#{project.path_with_namespace}/compare/%s...%s",
      )
  end
end
