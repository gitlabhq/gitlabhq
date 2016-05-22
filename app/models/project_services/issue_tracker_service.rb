class IssueTrackerService < Service

  validates :project_url, :issues_url, :new_issue_url, presence: true, url: true, if: :activated?

  default_value_for :category, 'issue_tracker'

  def default?
    default
  end

  def issue_url(iid)
    self.issues_url.gsub(':id', iid.to_s)
  end

  def project_path
    project_url
  end

  def new_issue_path
    new_issue_url
  end

  def issue_path(iid)
    issue_url(iid)
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

    message = "#{self.type} 无法访问 #{self.project_url}。请检查连接后重试。"
    result = false

    begin
      response = HTTParty.head(self.project_url, verify: true)

      if response
        message = "#{self.type} 尝试连接 #{self.project_url} 收到响应 #{response.code} "
        result = true
      end
    rescue HTTParty::Error, Timeout::Error, SocketError, Errno::ECONNRESET, Errno::ECONNREFUSED => error
      message = "#{self.type} 尝试连接 #{self.project_url} 发生错误 #{error.message}"
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
