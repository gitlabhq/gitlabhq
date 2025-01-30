# frozen_string_literal: true

module Clusters
  class AgentMigration < ApplicationRecord
    self.table_name = 'cluster_agent_migrations'

    belongs_to :cluster, optional: false, class_name: 'Clusters::Cluster'
    belongs_to :project, optional: false, class_name: '::Project'
    belongs_to :agent, optional: false, class_name: 'Clusters::Agent'
    belongs_to :issue, class_name: '::Issue'

    enum :agent_install_status, {
      pending: 0,
      in_progress: 1,
      success: 2,
      error: 3
    }, default: :pending, prefix: true

    validates :cluster, uniqueness: true
    validates :agent_install_message, length: { maximum: 255 }
  end
end
