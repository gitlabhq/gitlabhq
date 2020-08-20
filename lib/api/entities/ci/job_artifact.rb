# frozen_string_literal: true

module API
  module Entities
    module Ci
      class JobArtifact < Grape::Entity
        expose :file_type, :size, :filename, :file_format
      end
    end
  end
end
