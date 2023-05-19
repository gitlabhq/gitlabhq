# frozen_string_literal: true

module Gitlab
  module Ci
    class ProjectConfig
      class Bridge < Source
        def content
          return unless pipeline_source_bridge

          pipeline_source_bridge.yaml_for_downstream
        end

        def source
          :bridge_source
        end

        def url
          source_pipeline = pipeline_source_bridge.pipeline

          Repository.new(
            source_pipeline.project,
            source_pipeline.sha,
            custom_content,
            source_pipeline.source.to_sym,
            source_pipeline.source_bridge,
            source_pipeline
          ).url
        end
      end
    end
  end
end
