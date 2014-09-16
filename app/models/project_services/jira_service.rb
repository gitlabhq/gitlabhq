# == Schema Information
#
# Table name: services
#
#  id          :integer          not null, primary key
#  type        :string(255)
#  title       :string(255)
#  project_id  :integer          not null
#  created_at  :datetime
#  updated_at  :datetime
#  active      :boolean          default(FALSE), not null
#  properties  :text
#

class JiraService < Service
  include HTTParty

  prop_accessor :project_url, :username, :password,
                :api_version, :jira_issue_transition_id
  validates :username, :password, presence: true, if: :activated?
  before_validation :set_api_version

  def title
    'JIRA'
  end

  def description
    'Bug, issue tracking, and project management system'
  end

  def to_param
    'jira'
  end

  def fields
    [
      { type: 'text', name: 'project_url', placeholder: 'Url to JIRA, http://jira.example' },
      { type: 'text', name: 'username', placeholder: '' },
      { type: 'password', name: 'password', placeholder: '' },
      { type: 'text', name: 'api_version', placeholder: '2' },
      { type: 'text', name: 'jira_issue_transition_id', placeholder: '2' }
    ]
  end

  def set_api_version
    self.api_version = "2"
  end

  def execute(push, issue = nil)
    close_issue(push, issue) if issue
  end

  private

  def close_issue(push_data, issue_name)
    url = close_issue_url(issue_name)
    commit_url = push_data[:commits].first[:url]

    message = {
      'update' => {
        'comment' => [{
          'add' => {
            'body' => "Issue solved with #{commit_url}"
          }
        }]
      },
      'transition' => {
        'id' => jira_issue_transition_id
      }
    }

    json_body = message.to_json
    Rails.logger.info("#{self.class.name}: sending POST with body #{json_body} to #{url}")

    JiraService.post(
      url,
      body: json_body,
      headers: {
        'Content-Type' => 'application/json',
        'Authorization' => "Basic #{auth}"
      }
    )
  end

  def close_issue_url(issue_name)
    "#{self.project_url.chomp("/")}/rest/api/#{self.api_version}/issue/#{issue_name}/transitions"
  end

  def auth
    require 'base64'
    Base64.urlsafe_encode64("#{self.username}:#{self.password}")
  end
end
