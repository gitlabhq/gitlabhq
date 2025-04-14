# frozen_string_literal: true

module Clusters
  module Agents
    module Authorizations
      module CiAccess
        class Finder
          def initialize(project, agent: nil)
            @project = project
            @agent = agent
          end

          def execute
            # closest, most-specific authorization for a given agent wins
            authorizations = project_authorizations + implicit_authorizations + group_authorizations
            authorizations += organization_authorizations if organization_agents_enabled?

            authorizations.uniq(&:agent_id)
          end

          private

          attr_reader :project, :agent

          def implicit_authorizations
            agents = agent&.project_id == project.id ? [agent] : project.cluster_agents

            agents.map do |agent|
              Clusters::Agents::Authorizations::CiAccess::ImplicitAuthorization.new(agent: agent)
            end
          end

          # rubocop: disable CodeReuse/ActiveRecord
          def project_authorizations
            namespace_ids = project.group ? all_namespace_ids : project.namespace_id

            query = Clusters::Agents::Authorizations::CiAccess::ProjectAuthorization
              .where(project_id: project.id)
              .joins(agent: :project)
              .preload(agent: :project)
              .where(cluster_agents: { projects: { namespace_id: namespace_ids } })
              .with_available_ci_access_fields(project)

            query = query.where(agent_id: agent.id) if agent
            query.to_a
          end

          def group_authorizations
            return [] unless project.group

            authorizations = Clusters::Agents::Authorizations::CiAccess::GroupAuthorization.arel_table

            ordered_ancestors_cte = Gitlab::SQL::CTE.new(
              :ordered_ancestors,
              project.group.self_and_ancestors(hierarchy_order: :asc).reselect(:id)
            )

            cte_join_sources = authorizations.join(ordered_ancestors_cte.table).on(
              authorizations[:group_id].eq(ordered_ancestors_cte.table[:id])
            ).join_sources

            query = Clusters::Agents::Authorizations::CiAccess::GroupAuthorization
              .with(ordered_ancestors_cte.to_arel)
              .joins(cte_join_sources)
              .joins(agent: :project)
              .with_available_ci_access_fields(project)
              .where(projects: { namespace_id: all_namespace_ids })
              .order(
                Arel.sql(
                  'agent_id, array_position(ARRAY(SELECT id FROM ordered_ancestors)::bigint[], ' \
                    'agent_group_authorizations.group_id)'
                )
              )
              .select('DISTINCT ON (agent_id) agent_group_authorizations.*')
              .preload(agent: :project)

            query = query.where(agent_id: agent.id) if agent
            query.to_a
          end

          def organization_authorizations
            query = Clusters::Agents::Authorizations::CiAccess::OrganizationAuthorization
              .joins(agent: :project)
              .preload(agent: :project)
              .where(cluster_agents: { projects: { organization_id: project.organization_id } })
              .with_available_ci_access_fields(project)

            query = query.where(agent_id: agent.id) if agent
            query.to_a
          end
          # rubocop: enable CodeReuse/ActiveRecord

          def all_namespace_ids
            project.root_ancestor.self_and_descendants.select(:id)
          end

          def organization_agents_enabled?
            ::Gitlab::CurrentSettings.organization_cluster_agent_authorization_enabled
          end
        end
      end
    end
  end
end
