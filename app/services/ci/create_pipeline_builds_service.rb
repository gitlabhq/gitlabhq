module Ci
  class CreatePipelineBuildsService < BaseService
    attr_reader :pipeline

    def execute(pipeline)
      @pipeline = pipeline

      new_builds.map do |build_attributes|
        create_build(build_attributes)
      end
    end

    private

    def create_build(build_attributes)
      build_attributes = build_attributes.merge(
        pipeline: pipeline,
        project: pipeline.project,
        ref: pipeline.ref,
        tag: pipeline.tag,
        user: current_user,
        trigger_request: trigger_request
      )
      pipeline.builds.create(build_attributes)
    end

    def new_builds
      @new_builds ||= pipeline.config_builds_attributes.
        reject { |build| existing_build_names.include?(build[:name]) }
    end

    def existing_build_names
      @existing_build_names ||= pipeline.builds.pluck(:name)
    end

    def trigger_request
      return @trigger_request if defined?(@trigger_request)

      @trigger_request ||= pipeline.trigger_requests.first
    end
  end
end
