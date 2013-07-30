# == Schema Information
#
# Table name: web_hooks
#
#  id                :integer          not null, primary key
#  url               :string(255)
#  project_id        :integer
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  type              :string(255)      default("ProjectHook")
#  service_id        :integer
#  github_compatible :boolean          default(FALSE), not null
#

class WebHook < ActiveRecord::Base
  include HTTParty

  attr_accessible :url, :github_compatible

  # HTTParty timeout
  default_timeout 10

  validates :url, presence: true,
                  format: { with: URI::regexp(%w(http https)), message: "should be a valid url" }

  def execute(data)
    options = {}
    if github_compatible
      payload = WebHook.github_compatible_data(data)
      options = {
        :body => {"payload" => payload.to_json}
      }
    else
      options = {
        :body => data.to_json,
        :headers => {"Content-Type" => "application/json"}
      }
    end

    post_url = url
    parsed_url = URI.parse(post_url)
    if parsed_url.userinfo.present?
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

  # Transforms the input into GitHub compatible format
  def self.github_compatible_data(data)
    r = data.deep_dup
    r[:repository][:url] = r[:repository][:homepage]

    r
  end
end
