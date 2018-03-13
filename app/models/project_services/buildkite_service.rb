require "addressable/uri"

class BuildkiteService < CiService
  include ReactiveService

  ENDPOINT = "https://buildkite.com".freeze

  prop_accessor :project_url, :token
  boolean_accessor :enable_ssl_verification

  validates :project_url, presence: true, url: true, if: :activated?
  validates :token, presence: true, if: :activated?

  after_save :compose_service_hook, if: :activated?

  def webhook_url
    "#{buildkite_endpoint('webhook')}/deliver/#{webhook_token}"
  end

  def compose_service_hook
    hook = service_hook || build_service_hook
    hook.url = webhook_url
    hook.enable_ssl_verification = !!enable_ssl_verification
    hook.save
  end

  def execute(data)
    return unless supported_events.include?(data[:object_kind])

    service_hook.execute(data)
  end

  def commit_status(sha, ref)
    with_reactive_cache(sha, ref) {|cached| cached[:commit_status] }
  end

  def commit_status_path(sha)
    "#{buildkite_endpoint('gitlab')}/status/#{status_token}.json?commit=#{sha}"
  end

  def build_page(sha, ref)
    "#{project_url}/builds?commit=#{sha}"
  end

  def title
    'Buildkite'
  end

  def description
    'Continuous integration and deployments'
  end

  def self.to_param
    'buildkite'
  end

  def fields
    [
      { type: 'text',
        name: 'token',
        placeholder: 'Buildkite project GitLab token', required: true },

      { type: 'text',
        name: 'project_url',
        placeholder: "#{ENDPOINT}/example/project", required: true },

      { type: 'checkbox',
        name: 'enable_ssl_verification',
        title: "Enable SSL verification" }
    ]
  end

  def calculate_reactive_cache(sha, ref)
    response = Gitlab::HTTP.get(commit_status_path(sha), verify: false)

    status =
      if response.code == 200 && response['status']
        response['status']
      else
        :error
      end

    { commit_status: status }
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

  def buildkite_endpoint(subdomain = nil)
    if subdomain.present?
      uri = Addressable::URI.parse(ENDPOINT)
      new_endpoint = "#{uri.scheme || 'http'}://#{subdomain}.#{uri.host}"

      if uri.port.present?
        "#{new_endpoint}:#{uri.port}"
      else
        new_endpoint
      end
    else
      ENDPOINT
    end
  end
end
