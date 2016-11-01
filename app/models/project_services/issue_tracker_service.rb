class IssueTrackerService < Service
  default_value_for :category, 'issue_tracker'

  # Pattern used to extract links from comments
  # Override this method on services that uses different patterns
  def reference_pattern
    @reference_pattern ||= %r{(\b[A-Z][A-Z0-9_]+-|#{Issue.reference_prefix})(?<issue>\d+)}
  end

  def default?
    default
  end

  def create_cross_reference_note
    # implement inside child
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

  # Initialize with default properties values
  # or receive a block with custom properties
  def initialize_properties(&block)
    return unless properties.nil?

    if enabled_in_gitlab_config
      if block_given?
        yield
      else
        self.properties = {
          title: issues_tracker['title'],
          project_url: issues_tracker['project_url'],
          issues_url: issues_tracker['issues_url'],
          new_issue_url: issues_tracker['new_issue_url']
        }
      end
    else
      self.properties = {}
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
      response = HTTParty.head(self.project_url, verify: true)

      if response
        message = "#{self.type} received response #{response.code} when attempting to connect to #{self.project_url}"
        result = true
      end
    rescue HTTParty::Error, Timeout::Error, SocketError, Errno::ECONNRESET, Errno::ECONNREFUSED => error
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
end
