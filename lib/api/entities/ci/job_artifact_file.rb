# frozen_string_literal: true

module API
  module Entities
    module Ci
      class JobArtifactFile < Grape::Entity
        expose :filename, documentation: { type: 'String', example: 'artifacts.zip' }
        expose :cached_size, as: :size, documentation: { type: 'Integer', example: 1000 }
      end
    end
  end
end
