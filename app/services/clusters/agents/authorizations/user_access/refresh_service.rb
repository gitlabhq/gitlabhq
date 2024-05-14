# frozen_string_literal: true

module Clusters
  module Agents
    module Authorizations
      module UserAccess
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
                agent.user_access_project_authorizations.upsert_configs(allowed_project_configurations)
                agent.user_access_project_authorizations.delete_unlisted(project_ids)
              end
            else
              agent.user_access_project_authorizations.delete_all(:delete_all)
            end
          end

          def refresh_groups!
            if allowed_group_configurations.present?
              group_ids = allowed_group_configurations.map { |config| config.fetch(:group_id) }

              agent.with_lock do
                agent.user_access_group_authorizations.upsert_configs(allowed_group_configurations)
                agent.user_access_group_authorizations.delete_unlisted(group_ids)
              end
            else
              agent.user_access_group_authorizations.delete_all(:delete_all)
            end
          end

          def allowed_project_configurations
            project_entries = extract_config_entries(entity: 'projects')

            return unless project_entries

            allowed_projects.where_full_path_in(project_entries.keys, preload_routes: false).map do |project|
              { project_id: project.id, config: user_access_as }
            end
          end
          strong_memoize_attr :allowed_project_configurations

          def allowed_group_configurations
            group_entries = extract_config_entries(entity: 'groups')

            return unless group_entries

            allowed_groups.where_full_path_in(group_entries.keys, preload_routes: false).map do |group|
              { group_id: group.id, config: user_access_as }
            end
          end
          strong_memoize_attr :allowed_group_configurations

          def extract_config_entries(entity:)
            config.dig('user_access', entity)
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

          def user_access_as
            @user_access_as ||= config['user_access']&.slice('access_as') || {}
          end
        end
      end
    end
  end
end
