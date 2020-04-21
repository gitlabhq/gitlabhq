# frozen_string_literal: true

class IssueTrackerService < Service
  validate :one_issue_tracker, if: :activated?, on: :manual_change

  # TODO: we can probably just delegate as part of
  # https://gitlab.com/gitlab-org/gitlab/issues/29404
  data_field :project_url, :issues_url, :new_issue_url

  default_value_for :category, 'issue_tracker'

  before_validation :handle_properties
  before_validation :set_default_data, on: :create

  # Pattern used to extract links from comments
  # Override this method on services that uses different patterns
  # This pattern does not support cross-project references
  # The other code assumes that this pattern is a superset of all
  # overridden patterns. See ReferenceRegexes.external_pattern
  def self.reference_pattern(only_long: false)
    if only_long
      /(\b[A-Z][A-Z0-9_]*-)#{Gitlab::Regex.issue}/
    else
      /(\b[A-Z][A-Z0-9_]*-|#{Issue.reference_prefix})#{Gitlab::Regex.issue}/
    end
  end

  # this  will be removed as part of https://gitlab.com/gitlab-org/gitlab/issues/29404
  def title
    if title_attribute = read_attribute(:title)
      title_attribute
    elsif self.properties && self.properties['title'].present?
      self.properties['title']
    else
      default_title
    end
  end

  # this  will be removed as part of https://gitlab.com/gitlab-org/gitlab/issues/29404
  def description
    if description_attribute = read_attribute(:description)
      description_attribute
    elsif self.properties && self.properties['description'].present?
      self.properties['description']
    else
      default_description
    end
  end

  def handle_properties
    # this has been moved from initialize_properties and should be improved
    # as part of https://gitlab.com/gitlab-org/gitlab/issues/29404
    return unless properties

    @legacy_properties_data = properties.dup
    data_values = properties.slice!('title', 'description')
    properties.each do |key, _|
      current_value = self.properties.delete(key)
      value = attribute_changed?(key) ? attribute_change(key).last : current_value

      write_attribute(key, value)
    end

    data_values.reject! { |key| data_fields.changed.include?(key) }
    data_values.slice!(*data_fields.attributes.keys)
    data_fields.assign_attributes(data_values) if data_values.present?

    self.properties = {}
  end

  def legacy_properties_data
    @legacy_properties_data ||= {}
  end

  def supports_data_fields?
    true
  end

  def data_fields
    issue_tracker_data || self.build_issue_tracker_data
  end

  def default?
    default
  end

  def issue_url(iid)
    issues_url.gsub(':id', iid.to_s)
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

  def initialize_properties
    {}
  end

  # Initialize with default properties values
  def set_default_data
    return unless issues_tracker.present?

    self.title ||= issues_tracker['title']

    # we don't want to override if we have set something
    return if project_url || issues_url || new_issue_url

    data_fields.project_url = issues_tracker['project_url']
    data_fields.issues_url = issues_tracker['issues_url']
    data_fields.new_issue_url = issues_tracker['new_issue_url']
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
    log_info(message)
    result
  end

  def support_close_issue?
    false
  end

  def support_cross_reference?
    false
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
    return if template? || instance?
    return if project.blank?

    if project.services.external_issue_trackers.where.not(id: id).any?
      errors.add(:base, _('Another issue tracker is already in use. Only one issue tracker service can be active at a time'))
    end
  end
end

IssueTrackerService.prepend_if_ee('EE::IssueTrackerService')
