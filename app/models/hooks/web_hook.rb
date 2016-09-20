class WebHook < ActiveRecord::Base
  include Sortable
  include HTTParty

  default_value_for :push_events, true
  default_value_for :issues_events, false
  default_value_for :confidential_issues_events, false
  default_value_for :note_events, false
  default_value_for :merge_requests_events, false
  default_value_for :tag_push_events, false
  default_value_for :build_events, false
  default_value_for :pipeline_events, false
  default_value_for :enable_ssl_verification, true

  scope :push_hooks, -> { where(push_events: true) }
  scope :tag_push_hooks, -> { where(tag_push_events: true) }

  # HTTParty timeout
  default_timeout Gitlab.config.gitlab.webhook_timeout

  validates :url, presence: true, url: true

  def execute(data, hook_name)
    parsed_url = URI.parse(url)
    if parsed_url.userinfo.blank?
      response = WebHook.post(url,
                              body: data.to_json,
                              headers: build_headers(hook_name),
                              verify: enable_ssl_verification)
    else
      post_url = url.gsub("#{parsed_url.userinfo}@", '')
      auth = {
        username: CGI.unescape(parsed_url.user),
        password: CGI.unescape(parsed_url.password),
      }
      response = WebHook.post(post_url,
                              body: data.to_json,
                              headers: build_headers(hook_name),
                              verify: enable_ssl_verification,
                              basic_auth: auth)
    end

    [response.code, response.to_s]
  rescue SocketError, OpenSSL::SSL::SSLError, Errno::ECONNRESET, Errno::ECONNREFUSED, Net::OpenTimeout => e
    logger.error("WebHook Error => #{e}")
    [false, e.to_s]
  end

  def async_execute(data, hook_name)
    Sidekiq::Client.enqueue(ProjectWebHookWorker, id, data, hook_name)
  end

  private

  def build_headers(hook_name)
    headers = {
      'Content-Type' => 'application/json',
      'X-Gitlab-Event' => hook_name.singularize.titleize
    }
    headers['X-Gitlab-Token'] = token if token.present?
    headers
  end
end
