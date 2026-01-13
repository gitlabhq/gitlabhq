# frozen_string_literal: true

module API
  module Entities
    module Ci
      class JobArtifact < Grape::Entity
        expose :file_type,
          documentation: { type: 'String', values: ::Ci::JobArtifact.file_types.keys, example: 'archive' }
        expose :size, documentation: { type: 'Integer', example: 1000 }
        expose :filename, documentation: { type: 'String', example: 'artifacts.zip' }
        expose :file_format,
          documentation: { type: 'String', values: ::Ci::JobArtifact.file_formats.keys, example: 'zip' }
      end
    end
  end
end
