class IssueTrackerService < Service
  validate :one_issue_tracker, if: :activated?, on: :manual_change

  default_value_for :category, 'issue_tracker'

  # Pattern used to extract links from comments
  # Override this method on services that uses different patterns
  # This pattern does not support cross-project references
  # The other code assumes that this pattern is a superset of all
  # overriden patterns. See ReferenceRegexes::EXTERNAL_PATTERN
  def self.reference_pattern(only_long: false)
    if only_long
      /(\b[A-Z][A-Z0-9_]+-)(?<issue>\d+)/
    else
      /(\b[A-Z][A-Z0-9_]+-|#{Issue.reference_prefix})(?<issue>\d+)/
    end
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

  def issue_tracker_path
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
      { type: 'text', name: 'project_url', placeholder: 'Project url', required: true },
      { type: 'text', name: 'issues_url', placeholder: 'Issue url', required: true },
      { type: 'text', name: 'new_issue_url', placeholder: 'New Issue url', required: true }
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

  def self.supported_events
    %w(push)
  end

  def execute(data)
    return unless supported_events.include?(data[:object_kind])

    message = "#{self.type} was unable to reach #{self.project_url}. Check the url and try again."
    result = false

    begin
      response = Gitlab::HTTP.head(self.project_url, verify: true)

      if response
        message = "#{self.type} received response #{response.code} when attempting to connect to #{self.project_url}"
        result = true
      end
    rescue Gitlab::HTTP::Error, Timeout::Error, SocketError, Errno::ECONNRESET, Errno::ECONNREFUSED, OpenSSL::SSL::SSLError => error
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

  def one_issue_tracker
    return if template?
    return if project.blank?

    if project.services.external_issue_trackers.where.not(id: id).any?
      errors.add(:base, 'Another issue tracker is already in use. Only one issue tracker service can be active at a time')
    end
  end
end
