# frozen_string_literal: true

module API
  module Entities
    module Ml
      module MlflowArtifacts
        class Artifact < Grape::Entity
          expose :path, documentation: { type: 'String', desc: 'Artifact path' }
          expose :file_size, documentation: { type: 'Integer', desc: 'Artifact size' }
          expose :is_dir, documentation: { type: 'Boolean', desc: 'Is directory' }

          private

          def path
            object.file_name
          end

          def is_dir # rubocop:disable Naming/PredicateName -- It's the name of the mlflow attribute
            false
          end

          def file_size
            object.size
          end
        end
      end
    end
  end
end
