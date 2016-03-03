# == Schema Information
#
# Table name: web_hooks
#
#  id                      :integer          not null, primary key
#  url                     :string(2000)
#  project_id              :integer
#  created_at              :datetime
#  updated_at              :datetime
#  type                    :string           default("ProjectHook")
#  service_id              :integer
#  push_events             :boolean          default(TRUE), not null
#  issues_events           :boolean          default(FALSE), not null
#  merge_requests_events   :boolean          default(FALSE), not null
#  tag_push_events         :boolean          default(FALSE)
#  note_events             :boolean          default(FALSE), not null
#  enable_ssl_verification :boolean          default(TRUE)
#  build_events            :boolean          default(FALSE), not null
#

class WebHook < ActiveRecord::Base
  include Sortable
  include HTTParty

  default_value_for :push_events, true
  default_value_for :issues_events, false
  default_value_for :note_events, false
  default_value_for :merge_requests_events, false
  default_value_for :tag_push_events, false
  default_value_for :build_events, false
  default_value_for :enable_ssl_verification, true

  # HTTParty timeout
  default_timeout Gitlab.config.gitlab.webhook_timeout

  validates :url, presence: true, url: true

  def execute(data, hook_name)
    parsed_url = URI.parse(url)
    if parsed_url.userinfo.blank?
      response = WebHook.post(url,
                              body: data.to_json,
                              headers: {
                                  "Content-Type" => "application/json",
                                  "X-Gitlab-Event" => hook_name.singularize.titleize
                              },
                              verify: enable_ssl_verification)
    else
      post_url = url.gsub("#{parsed_url.userinfo}@", "")
      auth = {
        username: CGI.unescape(parsed_url.user),
        password: CGI.unescape(parsed_url.password),
      }
      response = WebHook.post(post_url,
                              body: data.to_json,
                              headers: {
                                  "Content-Type" => "application/json",
                                  "X-Gitlab-Event" => hook_name.singularize.titleize
                              },
                              verify: enable_ssl_verification,
                              basic_auth: auth)
    end

    [(response.code >= 200 && response.code < 300), ActionView::Base.full_sanitizer.sanitize(response.to_s)]
  rescue SocketError, OpenSSL::SSL::SSLError, Errno::ECONNRESET, Errno::ECONNREFUSED, Net::OpenTimeout => e
    logger.error("WebHook Error => #{e}")
    [false, e.to_s]
  end

  def async_execute(data, hook_name)
    Sidekiq::Client.enqueue(ProjectWebHookWorker, id, data, hook_name)
  end
end
