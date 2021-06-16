# frozen_string_literal: true

# rubocop: disable Style/Documentation
class Gitlab::BackgroundMigration::UpdateJiraTrackerDataDeploymentTypeBasedOnUrl
  # rubocop: disable Gitlab/NamespacedClass
  class JiraTrackerData < ActiveRecord::Base
    self.table_name = "jira_tracker_data"
    self.inheritance_column = :_type_disabled

    include ::Integrations::BaseDataFields
    attr_encrypted :url, encryption_options
    attr_encrypted :api_url, encryption_options

    enum deployment_type: { unknown: 0, server: 1, cloud: 2 }, _prefix: :deployment
  end
  # rubocop: enable Gitlab/NamespacedClass

  # https://rubular.com/r/uwgK7k9KH23efa
  JIRA_CLOUD_REGEX = %r{^https?://[A-Za-z0-9](?:[A-Za-z0-9\-]{0,61}[A-Za-z0-9])?\.atlassian\.net$}ix.freeze

  # rubocop: disable CodeReuse/ActiveRecord
  def perform(start_id, end_id)
    trackers_data = JiraTrackerData
      .where(deployment_type: 'unknown')
      .where(id: start_id..end_id)

    cloud, server = trackers_data.partition { |tracker_data| tracker_data.url.match?(JIRA_CLOUD_REGEX) }

    cloud_mappings = cloud.each_with_object({}) do |tracker_data, hash|
      hash[tracker_data] = { deployment_type: 2 }
    end

    server_mapppings = server.each_with_object({}) do |tracker_data, hash|
      hash[tracker_data] = { deployment_type: 1 }
    end

    mappings = cloud_mappings.merge(server_mapppings)

    ::Gitlab::Database::BulkUpdate.execute(%i[deployment_type], mappings)
  end
  # rubocop: enable CodeReuse/ActiveRecord
end
