# frozen_string_literal: true

module Clusters
  module Agents
    class ManagedResource < ApplicationRecord
      self.table_name = 'clusters_managed_resources'

      belongs_to :build, class_name: 'Ci::Build'
      belongs_to :cluster_agent, class_name: 'Clusters::Agent'
      belongs_to :project
      belongs_to :environment

      validates :template_name, length: { maximum: 1024 }

      enum :status, {
        processing: 0,
        completed: 1,
        failed: 2
      }
    end
  end
end
