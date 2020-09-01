# frozen_string_literal: true

class ProjectFeatureUsage < ApplicationRecord
  self.primary_key = :project_id

  JIRA_DVCS_CLOUD_FIELD = 'jira_dvcs_cloud_last_sync_at'.freeze
  JIRA_DVCS_SERVER_FIELD = 'jira_dvcs_server_last_sync_at'.freeze

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
    transaction(requires_new: true) do
      save unless persisted?
      touch(self.class.jira_dvcs_integration_field(cloud: cloud))
    end
  rescue ActiveRecord::RecordNotUnique
    reset
    retry
  end
end
