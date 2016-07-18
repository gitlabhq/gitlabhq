module Ci
  class CreatePipelineBuildsService < BaseService
    attr_reader :pipeline

    def execute(pipeline)
      @pipeline = pipeline

      return unless pipeline.config_processor

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
      @new_builds ||= pipeline.builds_attributes.
        reject { |build| existing_builds.include?(build[:name]) }
    end

    def existing_builds
      @existing_builds ||= pipeline.builds.pluck(:name)
    end

    def builds_attributes
      pipeline.config_processor.
        builds_for_ref(ref, tag?, trigger_request).
        sort_by { |build| build[:stage_idx] }
    end

    def trigger_request
      return @trigger_request if defined?(@trigger_request)
      @trigger_request ||= pipeline.trigger_requests.first
    end
  end
end
