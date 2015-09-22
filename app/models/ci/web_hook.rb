# == Schema Information
#
# Table name: web_hooks
#
#  id         :integer          not null, primary key
#  url        :string(255)      not null
#  project_id :integer          not null
#  created_at :datetime
#  updated_at :datetime
#

module Ci
  class WebHook < ActiveRecord::Base
    extend Ci::Model

    include HTTParty

    belongs_to :project, class_name: 'Ci::Project'

    # HTTParty timeout
    default_timeout 10

    validates :url, presence: true,
                    format: { with: URI::regexp(%w(http https)), message: "should be a valid url" }

    def execute(data)
      parsed_url = URI.parse(url)
      if parsed_url.userinfo.blank?
        Ci::WebHook.post(url, body: data.to_json, headers: { "Content-Type" => "application/json" }, verify: false)
      else
        post_url = url.gsub("#{parsed_url.userinfo}@", "")
        auth = {
          username: URI.decode(parsed_url.user),
          password: URI.decode(parsed_url.password),
        }
        Ci::WebHook.post(post_url,
                     body: data.to_json,
                     headers: { "Content-Type" => "application/json" },
                     verify: false,
                     basic_auth: auth)
      end
    end
  end
end
