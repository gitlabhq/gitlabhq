# == Schema Information
#
# Table name: web_hooks
#
#  id         :integer          not null, primary key
#  url        :string(255)
#  project_id :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  type       :string(255)      default("ProjectHook")
#  service_id :integer
#

class WebHook < ActiveRecord::Base
  include HTTParty

  attr_accessible :url

  # HTTParty timeout
  default_timeout 10

  validates :url, presence: true,
                  format: { with: URI::regexp(%w(http https)), message: "should be a valid url" }

  def execute(data)
    options = {}
    if Gitlab.config.gitlab.github_compatible_hooks
      options = {
        :body => {"payload" => data.to_json}
      }
    else
      options = {
        :body => data.to_json,
        :headers => {"Content-Type" => "application/json"}
      }
    end

    post_url = url
    parsed_url = URI.parse(post_url)
    if !parsed_url.userinfo.blank?
      options.merge!({
        :basic_auth => {
          username: URI.decode(parsed_url.user),
          password: URI.decode(parsed_url.password),
        }
      })
      post_url = url.gsub("#{parsed_url.userinfo}@", "")
    end

    WebHook.post(post_url, options)
  end

  def async_execute(data)
    Sidekiq::Client.enqueue(ProjectWebHookWorker, id, data)
  end
end
