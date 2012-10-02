class WebHook < ActiveRecord::Base
  include HTTParty

  attr_accessible :url

  # HTTParty timeout
  default_timeout 10

  validates :url, presence: true,
            format: { with: URI::regexp(%w(http https)), message: "should be a valid url" }

  def execute(data)
    parsed_url = URI.parse(url)
    if parsed_url.userinfo.blank?
      WebHook.post(url, body: data.to_json, headers: { "Content-Type" => "application/json" })
    else
      post_url = url.gsub("#{parsed_url.userinfo}@", "")
      WebHook.post(post_url,
                   body: data.to_json,
                   headers: {"Content-Type" => "application/json"},
                   basic_auth: {username: parsed_url.user, password: parsed_url.password})
    end
  end
end

# == Schema Information
#
# Table name: web_hooks
#
#  id         :integer         not null, primary key
#  url        :string(255)
#  project_id :integer
#  created_at :datetime        not null
#  updated_at :datetime        not null
#  type       :string(255)     default("ProjectHook")
#
