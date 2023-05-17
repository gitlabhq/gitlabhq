# frozen_string_literal: true

module Clusters
  class Agent < ApplicationRecord
    include FromUnion

    self.table_name = 'cluster_agents'

    INACTIVE_AFTER = 1.hour.freeze
    ACTIVITY_EVENT_LIMIT = 200

    belongs_to :created_by_user, class_name: 'User', optional: true
    belongs_to :project, class_name: '::Project' # Otherwise, it will load ::Clusters::Project

    has_many :agent_tokens, -> { order_last_used_at_desc }, class_name: 'Clusters::AgentToken', inverse_of: :agent
    has_many :active_agent_tokens, -> { active.order_last_used_at_desc }, class_name: 'Clusters::AgentToken', inverse_of: :agent

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

    def ci_access_authorized_for?(user)
      return false unless user
      return false unless ::Feature.enabled?(:expose_authorized_cluster_agents, project)

      ::Project.from_union(
        all_ci_access_authorized_projects_for(user).limit(1),
        all_ci_access_authorized_namespaces_for(user).limit(1)
      ).exists?
    end

    def user_access_authorized_for?(user)
      return false unless user
      return false unless ::Feature.enabled?(:expose_authorized_cluster_agents, project)

      Clusters::Agents::Authorizations::UserAccess::Finder
        .new(user, agent: self, preload: false, limit: 1).execute.any?
    end

    # As of today, all config values of associated authorization rows have the same value.
    # See `UserAccess::RefreshService` for more information.
    def user_access_config
      self.class.from_union(
        user_access_project_authorizations.select('config').limit(1),
        user_access_group_authorizations.select('config').limit(1)
      ).compact.first&.config
    end

    private

    def all_ci_access_authorized_projects_for(user)
      ::Project.joins(:ci_access_project_authorizations)
               .joins(:project_authorizations)
               .where(agent_project_authorizations: { agent_id: id })
               .where(project_authorizations: { user_id: user.id, access_level: Gitlab::Access::DEVELOPER.. })
    end

    def all_ci_access_authorized_namespaces_for(user)
      ::Project.with(root_namespace_cte.to_arel)
               .with(all_ci_access_authorized_namespaces_cte.to_arel)
               .joins('INNER JOIN all_authorized_namespaces ON all_authorized_namespaces.id = projects.namespace_id')
               .joins(:project_authorizations)
               .where(project_authorizations: { user_id: user.id, access_level: Gitlab::Access::DEVELOPER.. })
    end

    def root_namespace_cte
      Gitlab::SQL::CTE.new(:root_namespace, root_namespace.to_sql)
    end

    def all_ci_access_authorized_namespaces_cte
      Gitlab::SQL::CTE.new(:all_authorized_namespaces, all_ci_access_authorized_namespaces.to_sql)
    end

    def all_ci_access_authorized_namespaces
      Namespace.select("traversal_ids[array_length(traversal_ids, 1)] AS id")
               .joins("INNER JOIN root_namespace ON " \
                      "namespaces.traversal_ids @> ARRAY[root_namespace.root_id]")
               .joins("INNER JOIN agent_group_authorizations ON " \
                      "namespaces.traversal_ids @> ARRAY[agent_group_authorizations.group_id::integer]")
               .where(agent_group_authorizations: { agent_id: id })
    end

    def root_namespace
      Namespace.select("traversal_ids[1] AS root_id")
               .where("traversal_ids @> ARRAY(?)", project_namespace)
               .limit(1)
    end

    def project_namespace
      ::Project.select('namespace_id')
               .joins(:cluster_agents)
               .where(cluster_agents: { id: id })
               .limit(1)
    end
  end
end

Clusters::Agent.prepend_mod_with('Clusters::Agent')
