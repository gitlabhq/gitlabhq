# frozen_string_literal: true

module API
  module Entities
    module Provider
      class Gcp < Grape::Entity
        expose :cluster_id
        expose :status_name
        expose :gcp_project_id
        expose :zone
        expose :machine_type
        expose :num_nodes
        expose :endpoint
      end
    end
  end
end
