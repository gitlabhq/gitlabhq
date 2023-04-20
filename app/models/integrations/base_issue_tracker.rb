# frozen_string_literal: true

module Integrations
  class BaseIssueTracker < Integration
    validate :one_issue_tracker, if: :activated?, on: :manual_change

    attribute :category, default: 'issue_tracker'

    before_validation :handle_properties
    before_validation :set_default_data, on: :create

    # Pattern used to extract links from comments
    # Override this method on services that uses different patterns
    # This pattern does not support cross-project references
    # The other code assumes that this pattern is a superset of all
    # overridden patterns. See ReferenceRegexes.external_pattern
    def self.base_reference_pattern(only_long: false)
      if only_long
        /(\b[A-Z][A-Z0-9_]*-)#{Gitlab::Regex.issue}/
      else
        /(\b[A-Z][A-Z0-9_]*-|#{Issue.reference_prefix})#{Gitlab::Regex.issue}/
      end
    end

    def reference_pattern(only_long: false)
      self.class.base_reference_pattern(only_long: only_long)
    end

    def handle_properties
      # this has been moved from initialize_properties and should be improved
      # as part of https://gitlab.com/gitlab-org/gitlab/issues/29404
      return unless properties.present?

      safe_keys = data_fields.attributes.keys.grep_v(/encrypted/) - %w[id service_id created_at]

      @legacy_properties_data = properties.dup

      data_values = properties.slice(*safe_keys)
      data_values.reject! { |key| data_fields.changed.include?(key) }

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

    # Initialize with default properties values
    def set_default_data
      return unless issues_tracker.present?

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
      rescue Gitlab::HTTP::Error, Timeout::Error, SocketError, Errno::ECONNRESET, Errno::ECONNREFUSED, OpenSSL::SSL::SSLError => e
        message = "#{self.type} had an error when trying to connect to #{self.project_url}: #{e.message}"
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

    def create_cross_reference_note(external_issue, mentioned_in, author)
      # implement inside child
    end

    def activate_disabled_reason
      { trackers: other_external_issue_trackers } if other_external_issue_trackers.any?
    end

    private

    def other_external_issue_trackers
      return [] unless project_level?

      @other_external_issue_trackers ||= project.integrations.external_issue_trackers.where.not(id: id)
    end

    def enabled_in_gitlab_config
      Gitlab.config.issues_tracker &&
        Gitlab.config.issues_tracker.values.any? &&
        issues_tracker
    end

    def issues_tracker
      Gitlab.config.issues_tracker[to_param]
    end

    def one_issue_tracker
      return if instance?
      return if project.blank?

      if other_external_issue_trackers.any?
        errors.add(:base, _('Another issue tracker is already in use. Only one issue tracker service can be active at a time'))
      end
    end
  end
end
