# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Chain
        class Build
          class Associations < Chain::Base
            def perform!
              return unless @command.bridge

              @pipeline.build_source_pipeline(
                source_pipeline: @command.bridge.pipeline,
                source_project: @command.bridge.project,
                source_bridge: @command.bridge,
                project: @command.project
              )
            end

            def break?
              false
            end
          end
        end
      end
    end
  end
end
