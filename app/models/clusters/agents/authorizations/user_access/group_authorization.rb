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
        end
      end
    end
  end
end
