# == Schema Information
#
# Table name: services
#
#  id         :integer          not null, primary key
#  type       :string(255)
#  title      :string(255)
#  project_id :integer          not null
#  created_at :datetime
#  updated_at :datetime
#  active     :boolean          default(FALSE), not null
#  properties :text
#

class JiraService < IssueTrackerService
  include HTTParty
  include Rails.application.routes.url_helpers

  prop_accessor :username, :password, :api_version, :jira_issue_transition_id,
                :title, :description, :project_url, :issues_url, :new_issue_url

  before_validation :set_api_version, :set_jira_issue_transition_id

  def title
    if self.properties && self.properties['title'].present?
      self.properties['title']
    else
      'JIRA'
    end
  end

  def description
    if self.properties && self.properties['description'].present?
      self.properties['description']
    else
      'Jira issue tracker'
    end
  end

  def to_param
    'jira'
  end

  def fields
    super.push(
      { type: 'text', name: 'username', placeholder: '' },
      { type: 'password', name: 'password', placeholder: '' },
      { type: 'text', name: 'api_version', placeholder: '2' },
      { type: 'text', name: 'jira_issue_transition_id', placeholder: '2' }
    )
  end

  def execute(push, issue = nil)
    close_issue(push, issue.id) if issue
  end

  def create_cross_reference_note(mentioned, noteable, author)
    issue_name = mentioned.id
    project = self.project
    noteable_name = noteable.class.name.underscore.downcase.to_sym
    noteable_id = if noteable.is_a?(Commit)
                    noteable.id
                  else
                    noteable.iid
                  end

    data = {
      user: {
        name: author.name,
        url: resource_url(user_path(author)),
      },
      project: {
        name: project.path_with_namespace,
        url: resource_url(project_path(project))
      },
      entity: {
        name: noteable.class.name.underscore.humanize.downcase,
        url: resource_url(polymorphic_url([project, noteable_name], id: noteable_id, routing_type: :path))
      }
    }

    add_comment(data, issue_name)
  end

  private


  def set_api_version
    self.api_version ||= "2"
  end

  def set_jira_issue_transition_id
    self.jira_issue_transition_id ||= "2"
  end

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
    }.to_json

    send_message(url, message)
  end

  def add_comment(data, issue_name)
    url = add_comment_url(issue_name)
    user_name = data[:user][:name]
    user_url = data[:user][:url]
    entity_name = data[:entity][:name]
    entity_url = data[:entity][:url]
    entity_iid = data[:entity][:iid]
    project_name = data[:project][:name]
    project_url = data[:project][:url]

    message = {
      body: "[#{user_name}|#{user_url}] mentioned #{issue_name} in #{entity_name} of [#{project_name}|#{entity_url}]."
    }.to_json

    send_message(url, message)
  end

  def close_issue_url(issue_name)
    "#{server_url}/rest/api/#{self.api_version}/issue/#{issue_name}/transitions"
  end

  def add_comment_url(issue_name)
    "#{server_url}/rest/api/#{self.api_version}/issue/#{issue_name}/comment"
  end

  def auth
    require 'base64'
    Base64.urlsafe_encode64("#{self.username}:#{self.password}")
  end

  def send_message(url, message)
    begin
      result = JiraService.post(
        url,
        body: message,
        headers: {
          'Content-Type' => 'application/json',
          'Authorization' => "Basic #{auth}"
        }
      )
    rescue URI::InvalidURIError => e
      result = e.message
    end

    message = if result.is_a?(String)
                "#{self.class.name} ERROR: #{result}. Hostname: #{url}."
              else
                case result.code
                when 201, 200
                  "#{self.class.name} SUCCESS 201: Sucessfully posted to #{url}."
                when 401
                  "#{self.class.name} ERROR 401: Unauthorized. Check the #{self.username} credentials and JIRA access permissions and try again."
                else
                  "#{self.class.name} ERROR #{result.code}: #{result.parsed_response}"
                end
              end

    Rails.logger.info(message)
    message
  end

  def server_url
    server = URI(project_url)
    default_ports = [80, 443].include?(server.port)
    server_url = "#{server.scheme}://#{server.host}"
    server_url.concat(":#{server.port}") unless default_ports
    return server_url
  end

  def resource_url(resource)
    "#{Settings.gitlab['url'].chomp("/")}#{resource}"
  end
end
