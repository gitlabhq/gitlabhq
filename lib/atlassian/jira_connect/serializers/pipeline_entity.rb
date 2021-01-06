# frozen_string_literal: true

module Atlassian
  module JiraConnect
    module Serializers
      # Both this an BuildEntity represent a Ci::Pipeline
      class PipelineEntity < Grape::Entity
        include Gitlab::Routing

        format_with(:string, &:to_s)

        expose :id, format_with: :string
        expose :display_name, as: :displayName
        expose :url

        private

        alias_method :pipeline, :object
        delegate :project, to: :object

        def display_name
          "#{project.name} pipeline #{pipeline.iid}"
        end

        def url
          project_pipeline_url(project, pipeline)
        end
      end
    end
  end
end
