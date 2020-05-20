# frozen_string_literal: true

module Ci
  class JobArtifactsFinder
    def initialize(project, params = {})
      @project = project
      @params = params
    end

    def execute
      artifacts = @project.job_artifacts

      sort(artifacts)
    end

    private

    def sort_key
      @params[:sort] || 'created_desc'
    end

    def sort(artifacts)
      artifacts.order_by(sort_key)
    end
  end
end
