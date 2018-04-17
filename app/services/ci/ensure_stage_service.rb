module Ci
  ##
  # We call this service everytime we persist a CI/CD job.
  #
  # In most cases a job should already have a stage assigned,  but in cases it
  # doesn't have we need to either find existing one or create a brand new
  # stage.
  #
  class EnsureStageService < BaseService
    EnsureStageError = Class.new(StandardError)

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

    def ensure_stage(attempts: 2)
      find_stage || create_stage
    rescue ActiveRecord::RecordNotUnique
      retry if (attempts -= 1) > 0

      raise EnsureStageError, <<~EOS
        We failed to find or create a unique pipeline stage after 2 retries.
        This should never happen and is most likely the result of a bug in
        the database load balancing code.
      EOS
    end

    def find_stage
      @build.pipeline.stages.find_by(name: @build.stage)
    end

    def create_stage
      Ci::Stage.create!(name: @build.stage,
                        index: @build.stage_idx,
                        pipeline: @build.pipeline,
                        project: @build.project)
    end
  end
end
