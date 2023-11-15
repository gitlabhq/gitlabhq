# frozen_string_literal: true

module API
  module Entities
    module Ci
      module JobRequest
        class Image < Grape::Entity
          expose :name, :entrypoint
          expose :ports, using: Entities::Ci::JobRequest::Port

          expose :executor_opts
          expose :pull_policy
        end
      end
    end
  end
end
