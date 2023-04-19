# frozen_string_literal: true

module Clusters
  module Agents
    module Authorizations
      module UserAccess
        class GroupAuthorization < ApplicationRecord
          self.table_name = 'agent_user_access_group_authorizations'

          belongs_to :agent, class_name: 'Clusters::Agent', optional: false
          belongs_to :group, class_name: '::Group', optional: false

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
          end
        end
      end
    end
  end
end
