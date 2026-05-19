# frozen_string_literal: true

module Import
  module Offline
    module Imports
      module Projects
        class Stage < ::BulkImports::Stage
          private

          def config
            {
              finisher: {
                pipeline: ::BulkImports::Common::Pipelines::EntityFinisher,
                stage: 0
              }
            }
          end
        end
      end
    end
  end
end
