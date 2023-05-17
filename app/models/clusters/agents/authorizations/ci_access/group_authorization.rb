# frozen_string_literal: true

module Clusters
  module Agents
    module Authorizations
      module CiAccess
        class GroupAuthorization < ApplicationRecord
          include ConfigScopes

          self.table_name = 'agent_group_authorizations'

          belongs_to :agent, class_name: 'Clusters::Agent', optional: false
          belongs_to :group, class_name: '::Group', optional: false

          validates :config, json_schema: { filename: 'clusters_agents_authorizations_ci_access_config' }

          def config_project
            agent.project
          end
        end
      end
    end
  end
end
