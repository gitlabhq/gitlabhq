# frozen_string_literal: true

module Clusters
  module Agents
    module Authorizations
      module UserAccess
        module Scopes
          extend ActiveSupport::Concern

          included do
            scope :for_agent, ->(agent) { where(agent: agent) }
            scope :preloaded, -> { joins(agent: :project).preload(agent: :project) }
          end
        end
      end
    end
  end
end
