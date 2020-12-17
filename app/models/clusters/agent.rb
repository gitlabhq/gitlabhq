# frozen_string_literal: true

module Clusters
  class Agent < ApplicationRecord
    self.table_name = 'cluster_agents'

    belongs_to :project, class_name: '::Project' # Otherwise, it will load ::Clusters::Project

    has_many :agent_tokens, class_name: 'Clusters::AgentToken'

    scope :ordered_by_name, -> { order(:name) }
    scope :with_name, -> (name) { where(name: name) }

    validates :name,
      presence: true,
      length: { maximum: 63 },
      uniqueness: { scope: :project_id },
      format: {
        with: Gitlab::Regex.cluster_agent_name_regex,
        message: Gitlab::Regex.cluster_agent_name_regex_message
      }

    def has_access_to?(requested_project)
      requested_project == project
    end
  end
end
