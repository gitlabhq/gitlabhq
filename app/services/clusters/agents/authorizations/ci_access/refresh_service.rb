# frozen_string_literal: true

module Clusters
  module Agents
    module Authorizations
      module CiAccess
        class RefreshService
          include Gitlab::Utils::StrongMemoize

          AUTHORIZED_ENTITY_LIMIT = 500

          delegate :project, to: :agent, private: true
          delegate :root_ancestor, to: :project, private: true

          def initialize(agent, config:)
            @agent = agent
            @config = config
          end

          def execute
            refresh_projects!
            refresh_groups!

            true
          end

          private

          attr_reader :agent, :config

          def refresh_projects!
            if allowed_project_configurations.present?
              project_ids = allowed_project_configurations.map { |config| config.fetch(:project_id) }

              agent.with_lock do
                agent.ci_access_project_authorizations.upsert_all(allowed_project_configurations, unique_by: [:agent_id, :project_id])
                agent.ci_access_project_authorizations.where.not(project_id: project_ids).delete_all # rubocop: disable CodeReuse/ActiveRecord
              end
            else
              agent.ci_access_project_authorizations.delete_all(:delete_all)
            end
          end

          def refresh_groups!
            if allowed_group_configurations.present?
              group_ids = allowed_group_configurations.map { |config| config.fetch(:group_id) }

              agent.with_lock do
                agent.ci_access_group_authorizations.upsert_all(allowed_group_configurations, unique_by: [:agent_id, :group_id])
                agent.ci_access_group_authorizations.where.not(group_id: group_ids).delete_all # rubocop: disable CodeReuse/ActiveRecord
              end
            else
              agent.ci_access_group_authorizations.delete_all(:delete_all)
            end
          end

          def allowed_project_configurations
            strong_memoize(:allowed_project_configurations) do
              project_entries = extract_config_entries(entity: 'projects')

              if project_entries
                allowed_projects.where_full_path_in(project_entries.keys).map do |project|
                  { project_id: project.id, config: project_entries[project.full_path.downcase] }
                end
              end
            end
          end

          def allowed_group_configurations
            strong_memoize(:allowed_group_configurations) do
              group_entries = extract_config_entries(entity: 'groups')

              if group_entries
                allowed_groups.where_full_path_in(group_entries.keys).map do |group|
                  { group_id: group.id, config: group_entries[group.full_path.downcase] }
                end
              end
            end
          end

          def extract_config_entries(entity:)
            config.dig('ci_access', entity)
              &.first(AUTHORIZED_ENTITY_LIMIT)
              &.index_by { |config| config.delete('id').downcase }
          end

          def allowed_projects
            root_ancestor.all_projects
          end

          def allowed_groups
            if group_root_ancestor?
              root_ancestor.self_and_descendants
            else
              ::Group.none
            end
          end

          def group_root_ancestor?
            root_ancestor.group_namespace?
          end
        end
      end
    end
  end
end
