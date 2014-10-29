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

require "addressable/uri"

class BuildboxService < CiService
  prop_accessor :project_url, :token

  validates :project_url, presence: true, if: :activated?
  validates :token, presence: true, if: :activated?

  after_save :compose_service_hook, if: :activated?

  def webhook_url
    "#{buildbox_endpoint('webhook')}/deliver/#{webhook_token}"
  end

  def compose_service_hook
    hook = service_hook || build_service_hook
    hook.url = webhook_url
    hook.save
  end

  def execute(data)
    service_hook.execute(data)
  end

  def commit_status(sha)
    response = HTTParty.get(commit_status_path(sha), verify: false)

    if response.code == 200 && response['status']
      response['status']
    else
      :error
    end
  end

  def commit_status_path(sha)
    "#{buildbox_endpoint('gitlab')}/status/#{status_token}.json?commit=#{sha}"
  end

  def build_page(sha)
    "#{project_url}/builds?commit=#{sha}"
  end

  def builds_path
    "#{project_url}/builds?branch=#{project.default_branch}"
  end

  def status_img_path
    "#{buildbox_endpoint('badge')}/#{status_token}.svg"
  end

  def title
    'Buildbox'
  end

  def description
    'Continuous integration and deployments'
  end

  def to_param
    'buildbox'
  end

  def fields
    [
      { type: 'text',
        name: 'token',
        placeholder: 'Buildbox project GitLab token' },

      { type: 'text',
        name: 'project_url',
        placeholder: 'https://buildbox.io/example/project' }
    ]
  end

  private

  def webhook_token
    token_parts.first
  end

  def status_token
    token_parts.second
  end

  def token_parts
    if token.present?
      token.split(':')
    else
      []
    end
  end

  def buildbox_endpoint(subdomain = nil)
    endpoint = 'https://buildbox.io'

    if subdomain.present?
      uri = Addressable::URI.parse(endpoint)
      new_endpoint = "#{uri.scheme || 'http'}://#{subdomain}.#{uri.host}"

      if uri.port.present?
        "#{new_endpoint}:#{uri.port}"
      else
        new_endpoint
      end
    else
      endpoint
    end
  end
end
