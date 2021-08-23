# frozen_string_literal: true

module Clusters
  module Agents
    class RefreshAuthorizationService
      include Gitlab::Utils::StrongMemoize

      AUTHORIZED_GROUP_LIMIT = 100

      delegate :project, to: :agent, private: true

      def initialize(agent, config:)
        @agent = agent
        @config = config
      end

      def execute
        if allowed_group_configurations.present?
          group_ids = allowed_group_configurations.map { |config| config.fetch(:group_id) }

          agent.with_lock do
            agent.group_authorizations.upsert_all(allowed_group_configurations, unique_by: [:agent_id, :group_id])
            agent.group_authorizations.where.not(group_id: group_ids).delete_all # rubocop: disable CodeReuse/ActiveRecord
          end
        else
          agent.group_authorizations.delete_all(:delete_all)
        end

        true
      end

      private

      attr_reader :agent, :config

      def allowed_group_configurations
        strong_memoize(:allowed_group_configurations) do
          group_entries = config.dig('ci_access', 'groups')&.first(AUTHORIZED_GROUP_LIMIT)

          if group_entries
            groups_by_path = group_entries.index_by { |config| config.delete('id') }

            allowed_groups.where_full_path_in(groups_by_path.keys).map do |group|
              { group_id: group.id, config: groups_by_path[group.full_path] }
            end
          end
        end
      end

      def allowed_groups
        if project.root_ancestor.group?
          project.root_ancestor.self_and_descendants
        else
          ::Group.none
        end
      end
    end
  end
end
