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
      { type: 'text', name: 'token', placeholder: 'Flowdock Git source token' }
    ]
  end

  def supported_events
    %w[push]
  end

  def execute(data)
    return unless supported_events.include?(data[:object_kind])

    Flowdock::Git.post(
      data[:ref],
      data[:before],
      data[:after],
      token: token,
      repo: project.repository.path_to_repo,
      repo_url: "#{Gitlab.config.gitlab.url}/#{project.path_with_namespace}",
      commit_url: "#{Gitlab.config.gitlab.url}/#{project.path_with_namespace}/commit/%s",
      diff_url: "#{Gitlab.config.gitlab.url}/#{project.path_with_namespace}/compare/%s...%s",
    )
  end
end
