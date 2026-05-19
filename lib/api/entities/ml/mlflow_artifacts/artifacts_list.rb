# frozen_string_literal: true

module API
  module Entities
    module Ml
      module MlflowArtifacts
        class ArtifactsList < Grape::Entity
          expose :files, using: ::API::Entities::Ml::MlflowArtifacts::Artifact, documentation: { is_array: true }
        end
      end
    end
  end
end
