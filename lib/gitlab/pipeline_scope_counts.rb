# frozen_string_literal: true

module Gitlab
  class PipelineScopeCounts
    attr_reader :project

    PIPELINES_COUNT_LIMIT = 1000

    def self.declarative_policy_class
      'Ci::ProjectPipelinesPolicy'
    end

    def initialize(current_user, project, params)
      @current_user = current_user
      @project = project
      @params = params
    end

    def all
      finder.execute.limit(PIPELINES_COUNT_LIMIT).count
    end

    def running
      finder({ scope: "running" }).execute.limit(PIPELINES_COUNT_LIMIT).count
    end

    def finished
      finder({ scope: "finished" }).execute.limit(PIPELINES_COUNT_LIMIT).count
    end

    def pending
      finder({ scope: "pending" }).execute.limit(PIPELINES_COUNT_LIMIT).count
    end

    private

    def finder(params = {})
      ::Ci::PipelinesFinder.new(@project, @current_user, @params.merge(params))
    end
  end
end
