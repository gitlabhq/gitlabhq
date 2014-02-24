# == Schema Information
#
# Table name: web_hooks
#
#  id                    :integer          not null, primary key
#  url                   :string(255)
#  project_id            :integer
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  type                  :string(255)      default("ProjectHook")
#  service_id            :integer
#  push_events           :boolean          default(TRUE), not null
#  issues_events         :boolean          default(FALSE), not null
#  merge_requests_events :boolean          default(FALSE), not null
#  payload_template      :text
#

class WebHook < ActiveRecord::Base
  include HTTParty

  attr_accessible :url, :payload_template

  # HTTParty timeout
  default_timeout 10

  validates :url, presence: true,
                  format: { with: URI::regexp(%w(http https)), message: "should be a valid url" }

  def execute(data)
  	
  	unless payload_template.try(:empty?)
      liquid_template = Liquid::Template.parse(payload_template)
      body_data = liquid_template.render(data.deep_stringify_keys)
    else
      body_data = data.to_json
    end
    
    parsed_url = URI.parse(url)
    if parsed_url.userinfo.blank?
      WebHook.post(url, body: body_data, headers: { "Content-Type" => "application/json" }, verify: false)
    else
      post_url = url.gsub("#{parsed_url.userinfo}@", "")
      auth = {
        username: URI.decode(parsed_url.user),
        password: URI.decode(parsed_url.password),
      }
      WebHook.post(post_url,
                   body: body_data,
                   headers: {"Content-Type" => "application/json"},
                   verify: false,
                   basic_auth: auth)
    end
  end

  def async_execute(data)
    Sidekiq::Client.enqueue(ProjectWebHookWorker, id, data)
  end
  
  private
  
    def set_default_payload_template
      self.payload_template = Default_Payload_Template
    end
end
