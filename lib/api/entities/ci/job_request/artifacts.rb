# frozen_string_literal: true

module API
  module Entities
    module Ci
      module JobRequest
        class Artifacts < Grape::Entity
          expose :name
          expose :untracked, expose_nil: false
          expose :paths
          expose :exclude, expose_nil: false
          expose :when
          expose :expire_in
          expose :artifact_type
          expose :artifact_format
        end
      end
    end
  end
end
