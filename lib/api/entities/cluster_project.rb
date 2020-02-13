# frozen_string_literal: true

module API
  module Entities
    class ClusterProject < Entities::Cluster
      expose :project, using: Entities::BasicProjectDetails
    end
  end
end
