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
      build_attributes = {
        stage_idx: build_attributes[:stage_idx],
        stage: build_attributes[:stage],
        commands: build_attributes[:commands],
        tag_list: build_attributes[:tag_list],
        name: build_attributes[:name],
        when: build_attributes[:when],
        allow_failure: build_attributes[:allow_failure],
        environment: build_attributes[:environment],
        yaml_variables: build_attributes[:yaml_variables],
        options: build_attributes[:options],
        pipeline: pipeline,
        project: pipeline.project,
        ref: pipeline.ref,
        tag: pipeline.tag,
        user: current_user,
        trigger_request: trigger_request
      }

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
