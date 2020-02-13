# frozen_string_literal: true

module API
  module Entities
    class ClusterGroup < Entities::Cluster
      expose :group, using: Entities::BasicGroupDetails
    end
  end
end
