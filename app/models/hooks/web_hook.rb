# == Schema Information
#
# Table name: web_hooks
#
#  id                    :integer          not null, primary key
#  url                   :string(255)
#  project_id            :integer
#  created_at            :datetime
#  updated_at            :datetime
#  type                  :string(255)      default("ProjectHook")
#  service_id            :integer
#  push_events           :boolean          default(TRUE), not null
#  issues_events         :boolean          default(FALSE), not null
#  merge_requests_events :boolean          default(FALSE), not null
#  tag_push_events       :boolean          default(FALSE)
#  note_events           :boolean          default(FALSE), not null
#

class WebHook < ActiveRecord::Base
  include Sortable
  include HTTParty

  default_value_for :push_events, true
  default_value_for :issues_events, false
  default_value_for :note_events, false
  default_value_for :merge_requests_events, false
  default_value_for :tag_push_events, false

  # HTTParty timeout
  default_timeout Gitlab.config.gitlab.webhook_timeout

  validates :url, presence: true,
                  format: { with: /\A#{URI.regexp(%w(http https))}\z/, message: "should be a valid url" }

  def execute(data, hook_name)
    parsed_url = URI.parse(url)
    if parsed_url.userinfo.blank?
      WebHook.post(url,
                   body: data.to_json,
                   headers: {
                     "Content-Type" => "application/json",
                     "X-Gitlab-Event" => hook_name.singularize.titleize
                   },
                   verify: false)
    else
      post_url = url.gsub("#{parsed_url.userinfo}@", "")
      auth = {
        username: URI.decode(parsed_url.user),
        password: URI.decode(parsed_url.password),
      }
      WebHook.post(post_url,
                   body: data.to_json,
                   headers: {
                     "Content-Type" => "application/json",
                     "X-Gitlab-Event" => hook_name.singularize.titleize
                   },
                   verify: false,
                   basic_auth: auth)
    end
  rescue SocketError, Errno::ECONNRESET, Errno::ECONNREFUSED, Net::OpenTimeout => e
    logger.error("WebHook Error => #{e}")
    false
  end

  def async_execute(data, hook_name)
    Sidekiq::Client.enqueue(ProjectWebHookWorker, id, data, hook_name)
  end
end
