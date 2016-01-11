# == Schema Information
#
# Table name: services
#
#  id                    :integer          not null, primary key
#  type                  :string(255)
#  title                 :string(255)
#  project_id            :integer
#  created_at            :datetime
#  updated_at            :datetime
#  active                :boolean          default(FALSE), not null
#  properties            :text
#  template              :boolean          default(FALSE)
#  push_events           :boolean          default(TRUE)
#  issues_events         :boolean          default(TRUE)
#  merge_requests_events :boolean          default(TRUE)
#  tag_push_events       :boolean          default(TRUE)
#  note_events           :boolean          default(TRUE), not null
#  build_events          :boolean          default(FALSE), not null
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
      { type: 'text', name: 'token', placeholder: 'Flowdock Git source token' }
    ]
  end

  def supported_events
    %w(push)
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
