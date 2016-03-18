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

require "gemnasium/gitlab_service"

class GemnasiumService < Service
  prop_accessor :token, :api_key
  validates :token, :api_key, presence: true, if: :activated?

  def title
    'Gemnasium'
  end

  def description
    'Gemnasium monitors your project dependencies and alerts you about updates and security vulnerabilities.'
  end

  def to_param
    'gemnasium'
  end

  def fields
    [
      { type: 'text', name: 'api_key', placeholder: 'Your personal API KEY on gemnasium.com ' },
      { type: 'text', name: 'token', placeholder: 'The project\'s slug on gemnasium.com' }
    ]
  end

  def supported_events
    %w(push)
  end

  def execute(data)
    return unless supported_events.include?(data[:object_kind])

    Gemnasium::GitlabService.execute(
      ref: data[:ref],
      before: data[:before],
      after: data[:after],
      token: token,
      api_key: api_key,
      repo: project.repository.path_to_repo
    )
  end
end
