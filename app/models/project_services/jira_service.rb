# == Schema Information
#
# Table name: services
#
#  id                    :integer          not null, primary key
#  type                  :string(255)
#  title                 :string(255)
#  project_id            :integer
#  created_at            :datetime
#  updated_at            :datetime
#  active                :boolean          default(FALSE), not null
#  properties            :text
#  template              :boolean          default(FALSE)
#  push_events           :boolean          default(TRUE)
#  issues_events         :boolean          default(TRUE)
#  merge_requests_events :boolean          default(TRUE)
#  tag_push_events       :boolean          default(TRUE)
#  note_events           :boolean          default(TRUE), not null
#  build_events          :boolean          default(FALSE), not null
#

class JiraService < IssueTrackerService
  include Gitlab::Routing.url_helpers

  validates :url, url: true, presence: true, if: :activated?
  validates :project_key, presence: true, if: :activated?

  prop_accessor :username, :password, :url, :project_key,
                :jira_issue_transition_id, :title, :description

  before_update :reset_password

  # {PROJECT-KEY}-{NUMBER} Examples: JIRA-1, PROJECT-1
  def reference_pattern
    @reference_pattern ||= %r{(?<issue>\b([A-Z][A-Z0-9_]+-)\d+)}
  end

  def initialize_properties
    super do
      self.properties = {
        title: issues_tracker['title'],
        url: issues_tracker['url']
      }
    end
  end

  def reset_password
    # don't reset the password if a new one is provided
    if url_changed? && !password_touched?
      self.password = nil
    end
  end

  def options
    url = URI.parse(self.url)

    {
      username: self.username,
      password: self.password,
      site: URI.join(url, '/').to_s,
      context_path: url.path,
      auth_type: :basic,
      read_timeout: 120,
      use_ssl: url.scheme == 'https'
    }
  end

  def client
    @client ||= JIRA::Client.new(options)
  end

  def jira_project
    @jira_project ||= client.Project.find(project_key)
  end

  def help
    'See the ' \
    '[integration doc](http://doc.gitlab.com/ce/integration/external-issue-tracker.html) '\
    'for details.'
  end

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
    [
      { type: 'text', name: 'url', title: 'URL', placeholder: 'https://jira.example.com' },
      { type: 'text', name: 'project_key', placeholder: 'Project Key' },
      { type: 'text', name: 'username', placeholder: '' },
      { type: 'password', name: 'password', placeholder: '' },
      { type: 'text', name: 'jira_issue_transition_id', placeholder: '2' }
    ]
  end

  # URLs to redirect from Gitlab issues pages to jira issue tracker
  def project_url
    "#{url}/issues/?jql=project=#{project_key}"
  end

  def issues_url
    "#{url}/browse/:id"
  end

  def new_issue_url
    "#{url}/secure/CreateIssue.jspa"
  end

  def execute(push, issue = nil)
    if issue.nil?
      # No specific issue, that means
      # we just want to test settings
      test_settings
    else
      close_issue(push, issue)
    end
  end

  def create_cross_reference_note(mentioned, noteable, author)
    issue_key = mentioned.id
    project = self.project
    noteable_name = noteable.class.name.underscore.downcase
    noteable_id = if noteable.is_a?(Commit)
                    noteable.id
                  else
                    noteable.iid
                  end

    entity_url = build_entity_url(noteable_name.to_sym, noteable_id)

    data = {
      user: {
        name: author.name,
        url: resource_url(user_path(author)),
      },
      project: {
        name: project.path_with_namespace,
        url: resource_url(namespace_project_path(project.namespace, project))
      },
      entity: {
        name: noteable_name.humanize.downcase,
        url: entity_url,
        title: noteable.title
      }
    }

    add_comment(data, issue_key)
  end

  def test_settings
    return unless url.present?
    # Test settings by getting the project
    jira_project

  rescue Errno::ECONNREFUSED, JIRA::HTTPError => e
    Rails.logger.info "#{self.class.name} ERROR: #{e.message}. API URL: #{url}."
    false
  end

  private

  def close_issue(entity, issue)
    commit_id = if entity.is_a?(Commit)
                  entity.id
                elsif entity.is_a?(MergeRequest)
                  entity.diff_head_sha
                end

    commit_url = build_entity_url(:commit, commit_id)

    # Depending on the JIRA project's workflow, a comment during transition
    # may or may not be allowed. Split the operation in to two calls so the
    # comment always works.
    transition_issue(issue)
    add_issue_solved_comment(issue, commit_id, commit_url)
  end

  def transition_issue(issue)
    issue = client.Issue.find(issue.iid)
    issue.transitions.build.save(transition: { id: jira_issue_transition_id })
  end

  def add_issue_solved_comment(issue, commit_id, commit_url)
    comment = "Issue solved with [#{commit_id}|#{commit_url}]."
    send_message(issue.iid, comment)
  end

  def add_comment(data, issue_key)
    user_name = data[:user][:name]
    user_url = data[:user][:url]
    entity_name = data[:entity][:name]
    entity_url = data[:entity][:url]
    entity_title = data[:entity][:title]
    project_name = data[:project][:name]

    message = "[#{user_name}|#{user_url}] mentioned this issue in [a #{entity_name} of #{project_name}|#{entity_url}]:\n'#{entity_title}'"

    unless comment_exists?(issue_key, message)
      send_message(issue_key, message)
    end
  end

  def comment_exists?(issue_key, message)
    comments = client.Issue.find(issue_key).comments
    comments.map { |comment| comment.body.include?(message) }.any?
  end

  def send_message(issue_key, message)
    return unless url.present?

    issue = client.Issue.find(issue_key)

    if issue.comments.build.save!(body: message)
      result_message = "#{self.class.name} SUCCESS: Successfully posted to #{url}."
    end

    Rails.logger.info(result_message)
    result_message
  rescue URI::InvalidURIError, Errno::ECONNREFUSED, JIRA::HTTPError => e
    Rails.logger.info "#{self.class.name} Send message ERROR: #{url} - #{e.message}"
  end

  def resource_url(resource)
    "#{Settings.gitlab.base_url.chomp("/")}#{resource}"
  end

  def build_entity_url(entity_name, entity_id)
    resource_url(
      polymorphic_url(
        [
          self.project.namespace.becomes(Namespace),
          self.project,
          entity_name
        ],
        id: entity_id,
        routing_type: :path
      )
    )
  end
end
