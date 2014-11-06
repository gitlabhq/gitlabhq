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

  def execute(push_data)
    Gemnasium::GitlabService.execute(
      ref: push_data[:ref],
      before: push_data[:before],
      after: push_data[:after],
      token: token,
      api_key: api_key,
      repo: project.repository.path_to_repo
      )
  end
end
