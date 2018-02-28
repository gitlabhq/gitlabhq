module Ci
  ##
  # We call this service everytime we persist a CI/CD job.
  #
  # In most cases a job should already have a stage assigned,  but in cases it
  # doesn't have we need to either find existing one or create a brand new
  # stage.
  #
  class EnsureStageService < BaseService
    def execute(build)
      @build = build

      return if build.stage_id.present?
      return if build.invalid?

      ensure_stage.tap do |stage|
        build.stage_id = stage.id

        yield stage if block_given?
      end
    end

    private

    def ensure_stage
      find_stage || create_stage
    end

    def find_stage
      @build.pipeline.stages.find_by(name: @build.stage)
    end

    def create_stage
      Ci::Stage.create!(name: @build.stage,
                        pipeline: @build.pipeline,
                        project: @build.project)
    end
  end
end
