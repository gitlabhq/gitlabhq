# frozen_string_literal: true

module Ci
  class PipelineCreationMetadata
    attr_reader :id, :project, :status, :pipeline_id

    REDIS_CACHE_KEY = "project:{%{project_full_path}}:ci_pipeline_creation:{%{pipeline_creation_id}}"
    STATUSES = [:creating, :failed, :succeeded].freeze

    def self.find(project:, id:)
      pipeline_creation_data = Rails.cache.read(
        format(REDIS_CACHE_KEY, project_full_path: project.full_path, pipeline_creation_id: id)
      )

      new(
        status: pipeline_creation_data[:status],
        id: id,
        project: project,
        pipeline_id: pipeline_creation_data[:pipeline_id]
      )
    end

    def initialize(project:, status: nil, id: nil, pipeline_id: nil)
      @id = id || generate_id
      @pipeline_id = pipeline_id
      @project = project
      @status = status || :creating
    end

    private

    def generate_id
      SecureRandom.uuid
    end
  end
end
