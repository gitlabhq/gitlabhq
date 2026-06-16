# frozen_string_literal: true

module Import
  module Offline
    module Imports
      module Projects
        class Stage < ::BulkImports::Stage
          private

          def config
            {
              project: {
                pipeline: Import::Offline::Projects::Pipelines::ProjectPipeline,
                stage: 0
              },
              finisher: {
                pipeline: ::BulkImports::Common::Pipelines::EntityFinisher,
                stage: 1
              }
            }
          end
        end
      end
    end
  end
end
