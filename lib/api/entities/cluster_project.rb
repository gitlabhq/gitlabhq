# frozen_string_literal: true

module API
  module Entities
    class ClusterProject < Entities::Cluster
      expose :project, using: ::API::Entities::BasicProjectDetails
    end
  end
end
