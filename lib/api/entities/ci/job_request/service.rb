# frozen_string_literal: true

module API
  module Entities
    module Ci
      module JobRequest
        class Service < Grape::Entity
          expose :name, :entrypoint
          expose :ports, using: Entities::Ci::JobRequest::Port

          expose :pull_policy
          expose :alias, :command
          expose :variables
        end
      end
    end
  end
end
