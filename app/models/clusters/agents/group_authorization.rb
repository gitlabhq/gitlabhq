# frozen_string_literal: true

module Clusters
  module Agents
    class GroupAuthorization < ApplicationRecord
      self.table_name = 'agent_group_authorizations'

      belongs_to :agent, class_name: 'Clusters::Agent', optional: false
      belongs_to :group, class_name: '::Group', optional: false

      validates :config, json_schema: { filename: 'cluster_agent_authorization_configuration' }
    end
  end
end
