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
#

class IssueTrackerService < Service

  validates :project_url, :issues_url, :new_issue_url, presence: true, if: :activated?

  def category
    :issue_tracker
  end

  def default?
    false
  end

  def issue_url(iid)
    self.issues_url.gsub(':id', iid.to_s)
  end

  def fields
    [
      { type: 'text', name: 'description', placeholder: description },
      { type: 'text', name: 'project_url', placeholder: 'Project url' },
      { type: 'text', name: 'issues_url', placeholder: 'Issue url' },
      { type: 'text', name: 'new_issue_url', placeholder: 'New Issue url' }
    ]
  end

  def initialize_properties
    if properties.nil?
      if enabled_in_gitlab_config
        self.properties = {
          title: issues_tracker['title'],
          project_url: add_issues_tracker_id(issues_tracker['project_url']),
          issues_url: add_issues_tracker_id(issues_tracker['issues_url']),
          new_issue_url: add_issues_tracker_id(issues_tracker['new_issue_url'])
        }
      else
        self.properties = {}
      end
    end
  end

  def supported_events
    %w(push)
  end

  def execute(data)
    return unless supported_events.include?(data[:object_kind])

    message = "#{self.type} was unable to reach #{self.project_url}. Check the url and try again."
    result = false

    begin
      url = URI.parse(self.project_url)

      if url.host && url.port
        http = Net::HTTP.start(url.host, url.port, { open_timeout: 5, read_timeout: 5 })
        response = http.head("/")

        if response
          message = "#{self.type} received response #{response.code} when attempting to connect to #{self.project_url}"
          result = true
        end
      end
    rescue Timeout::Error, SocketError, Errno::ECONNRESET, Errno::ECONNREFUSED => error
      message = "#{self.type} had an error when trying to connect to #{self.project_url}: #{error.message}"
    end
    Rails.logger.info(message)
    result
  end

  private

  def enabled_in_gitlab_config
    Gitlab.config.issues_tracker &&
    Gitlab.config.issues_tracker.values.any? &&
    issues_tracker
  end

  def issues_tracker
    Gitlab.config.issues_tracker[to_param]
  end

  def add_issues_tracker_id(url)
    if self.project
      id = self.project.issues_tracker_id

      if id
        url = url.gsub(":issues_tracker_id", id)
      end
    end

    url
  end
end
