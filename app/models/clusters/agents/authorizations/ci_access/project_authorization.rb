# frozen_string_literal: true

module Clusters
  module Agents
    module Authorizations
      module CiAccess
        class ProjectAuthorization < ApplicationRecord
          include ConfigScopes

          self.table_name = 'agent_project_authorizations'

          belongs_to :agent, class_name: 'Clusters::Agent', optional: false
          belongs_to :project, class_name: '::Project', optional: false

          validates :config, json_schema: { filename: 'clusters_agents_authorizations_ci_access_config' }

          def config_project
            agent.project
          end
        end
      end
    end
  end
end
