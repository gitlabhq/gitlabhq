# frozen_string_literal: true

class ProjectFeatureUsage < ApplicationRecord
  self.primary_key = :project_id

  JIRA_DVCS_CLOUD_FIELD = 'jira_dvcs_cloud_last_sync_at'
  JIRA_DVCS_SERVER_FIELD = 'jira_dvcs_server_last_sync_at'

  belongs_to :project
  validates :project, presence: true

  scope :with_jira_dvcs_integration_enabled, -> (cloud: true) do
    where.not(jira_dvcs_integration_field(cloud: cloud) => nil)
  end

  class << self
    def jira_dvcs_integration_field(cloud: true)
      cloud ? JIRA_DVCS_CLOUD_FIELD : JIRA_DVCS_SERVER_FIELD
    end
  end

  def log_jira_dvcs_integration_usage(cloud: true)
    ::Gitlab::Database::LoadBalancing::Session.without_sticky_writes do
      integration_field = self.class.jira_dvcs_integration_field(cloud: cloud)

      # The feature usage is used only once later to query the feature usage in a
      # long date range. Therefore, we just need to update the timestamp once per
      # day
      break if persisted? && updated_today?(integration_field)

      persist_jira_dvcs_usage(integration_field)
    end
  end

  private

  def updated_today?(integration_field)
    self[integration_field].present? && self[integration_field].today?
  end

  def persist_jira_dvcs_usage(integration_field)
    assign_attributes(integration_field => Time.current)
    save
  rescue ActiveRecord::RecordNotUnique
    reset
    retry
  end
end

ProjectFeatureUsage.prepend_mod_with('ProjectFeatureUsage')
