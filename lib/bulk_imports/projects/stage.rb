# frozen_string_literal: true

module BulkImports
  module Projects
    class Stage < ::BulkImports::Stage
      private

      def config
        @config ||= {
          group: {
            pipeline: BulkImports::Projects::Pipelines::ProjectPipeline,
            stage: 0
          },
          finisher: {
            pipeline: BulkImports::Common::Pipelines::EntityFinisher,
            stage: 1
          }
        }
      end
    end
  end
end

::BulkImports::Projects::Stage.prepend_mod_with('BulkImports::Projects::Stage')
