# frozen_string_literal: true

module API
  module Entities
    class JobArtifactFile < Grape::Entity
      expose :filename
      expose :cached_size, as: :size
    end
  end
end
