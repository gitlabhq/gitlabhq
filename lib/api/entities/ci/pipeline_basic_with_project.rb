# frozen_string_literal: true

module API
  module Entities
    module Ci
      class PipelineBasicWithProject < PipelineBasicWithMetadata
        expose :project, using: ::API::Entities::ProjectIdentity
      end
    end
  end
end
