# frozen_string_literal: true

module API
  module Entities
    class JobArtifact < Grape::Entity
      expose :file_type, :size, :filename, :file_format
    end
  end
end
