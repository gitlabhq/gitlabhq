# frozen_string_literal: true

module Clusters
  module Agents
    class ProjectAuthorization < ApplicationRecord
      self.table_name = 'agent_project_authorizations'

      belongs_to :agent, class_name: 'Clusters::Agent', optional: false
      belongs_to :project, class_name: '::Project', optional: false

      validates :config, json_schema: { filename: 'cluster_agent_authorization_configuration' }
    end
  end
end
