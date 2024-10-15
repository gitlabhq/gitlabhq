# frozen_string_literal: true

module API
  module Entities
    module Ml
      module MlflowArtifacts
        class ArtifactsList < Grape::Entity
          expose :files, with: ::API::Entities::Ml::MlflowArtifacts::Artifact
        end
      end
    end
  end
end
