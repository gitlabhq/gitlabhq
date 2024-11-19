# frozen_string_literal: true

module Clusters
  module Agents
    module Authorizations
      module UserAccess
        class GroupAuthorization < ApplicationRecord
          include Scopes

          self.table_name = 'agent_user_access_group_authorizations'

          belongs_to :agent, class_name: 'Clusters::Agent', optional: false
          belongs_to :group, class_name: '::Group', optional: false

          scope :for_user, ->(user) {
            with(groups_with_direct_membership_cte(user).to_arel)
              .with(all_groups_with_membership_cte.to_arel)
              .joins('INNER JOIN all_groups_with_membership ON ' \
                     'all_groups_with_membership.id = agent_user_access_group_authorizations.group_id')
              .select('DISTINCT ON (id) agent_user_access_group_authorizations.*, ' \
                      'all_groups_with_membership.access_level AS access_level')
              .order('id, access_level DESC')
          }

          scope :for_project, ->(project) {
            where(all_groups_with_membership: { id: project.namespace.self_and_ancestor_ids })
          }

          validates :config, json_schema: { filename: 'clusters_agents_authorizations_user_access_config' }

          def config_project
            agent.project
          end

          class << self
            def upsert_configs(configs)
              upsert_all(configs, unique_by: [:agent_id, :group_id])
            end

            def delete_unlisted(group_ids)
              where.not(group_id: group_ids).delete_all
            end

            def all_groups_with_membership_cte
              Gitlab::SQL::CTE.new(:all_groups_with_membership, all_groups_with_membership.to_sql)
            end

            def all_groups_with_membership
              ::Group.joins('INNER JOIN groups_with_direct_membership ON ' \
                            'namespaces.traversal_ids @> ARRAY[groups_with_direct_membership.id]')
                     .select('namespaces.id AS id, ' \
                             'groups_with_direct_membership.access_level AS access_level')
            end

            def groups_with_direct_membership_cte(user)
              Gitlab::SQL::CTE.new(:groups_with_direct_membership, groups_with_direct_membership_for(user).to_sql)
            end

            def groups_with_direct_membership_for(user)
              user
                .groups_with_active_memberships
                .merge(GroupMember.by_access_level(Gitlab::Access::DEVELOPER..))
                .select('namespaces.id AS id, members.access_level AS access_level')
            end
          end
        end
      end
    end
  end
end
