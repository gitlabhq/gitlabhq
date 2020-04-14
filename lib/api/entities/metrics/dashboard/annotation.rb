# frozen_string_literal: true

module API
  module Entities
    module Metrics
      module Dashboard
        class Annotation < Grape::Entity
          expose :id
          expose :starting_at
          expose :ending_at
          expose :dashboard_path
          expose :description
          expose :environment_id
          expose :cluster_id
        end
      end
    end
  end
end
