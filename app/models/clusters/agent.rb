# frozen_string_literal: true

module Clusters
  class Agent < ApplicationRecord
    self.table_name = 'cluster_agents'

    INACTIVE_AFTER = 1.hour.freeze
    ACTIVITY_EVENT_LIMIT = 200

    belongs_to :created_by_user, class_name: 'User', optional: true
    belongs_to :project, class_name: '::Project' # Otherwise, it will load ::Clusters::Project

    has_many :agent_tokens, -> { order_last_used_at_desc }, class_name: 'Clusters::AgentToken', inverse_of: :agent

    has_many :ci_access_group_authorizations, class_name: 'Clusters::Agents::Authorizations::CiAccess::GroupAuthorization'
    has_many :ci_access_authorized_groups, class_name: '::Group', through: :ci_access_group_authorizations, source: :group

    has_many :ci_access_project_authorizations, class_name: 'Clusters::Agents::Authorizations::CiAccess::ProjectAuthorization'
    has_many :ci_access_authorized_projects, class_name: '::Project', through: :ci_access_project_authorizations, source: :project

    has_many :user_access_group_authorizations, class_name: 'Clusters::Agents::Authorizations::UserAccess::GroupAuthorization'
    has_many :user_access_authorized_groups, class_name: '::Group', through: :user_access_group_authorizations, source: :group

    has_many :user_access_project_authorizations, class_name: 'Clusters::Agents::Authorizations::UserAccess::ProjectAuthorization'
    has_many :user_access_authorized_projects, class_name: '::Project', through: :user_access_project_authorizations, source: :project

    has_many :activity_events, -> { in_timeline_order }, class_name: 'Clusters::Agents::ActivityEvent', inverse_of: :agent

    scope :ordered_by_name, -> { order(:name) }
    scope :with_name, -> (name) { where(name: name) }
    scope :has_vulnerabilities, -> (value = true) { where(has_vulnerabilities: value) }

    validates :name,
      presence: true,
      length: { maximum: 63 },
      uniqueness: { scope: :project_id },
      format: {
        with: Gitlab::Regex.cluster_agent_name_regex,
        message: Gitlab::Regex.cluster_agent_name_regex_message
      }

    def has_access_to?(requested_project)
      requested_project == project
    end

    def connected?
      agent_tokens.active.where("last_used_at > ?", INACTIVE_AFTER.ago).exists?
    end

    def activity_event_deletion_cutoff
      # Order is defined by the association
      activity_events
        .offset(ACTIVITY_EVENT_LIMIT - 1)
        .pick(:recorded_at)
    end

    def to_ability_name
      :cluster
    end
  end
end

Clusters::Agent.prepend_mod_with('Clusters::Agent')
