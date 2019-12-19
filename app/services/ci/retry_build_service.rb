# frozen_string_literal: true

module Ci
  class RetryBuildService < ::BaseService
    CLONE_ACCESSORS = %i[pipeline project ref tag options name
                         allow_failure stage stage_id stage_idx trigger_request
                         yaml_variables when environment coverage_regex
                         description tag_list protected needs resource_group].freeze

    def execute(build)
      reprocess!(build).tap do |new_build|
        build.pipeline.mark_as_processable_after_stage(build.stage_idx)

        new_build.enqueue!

        MergeRequests::AddTodoWhenBuildFailsService
          .new(project, current_user)
          .close(new_build)
      end
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def reprocess!(build)
      unless can?(current_user, :update_build, build)
        raise Gitlab::Access::AccessDeniedError
      end

      attributes = CLONE_ACCESSORS.map do |attribute|
        [attribute, build.public_send(attribute)] # rubocop:disable GitlabSecurity/PublicSend
      end

      attributes.push([:user, current_user])

      build.retried = true

      Ci::Build.transaction do
        # mark all other builds of that name as retried
        build.pipeline.builds.latest
          .where(name: build.name)
          .update_all(retried: true)

        create_build!(attributes)
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord

    private

    def create_build!(attributes)
      build = project.builds.new(Hash[attributes])
      build.deployment = ::Gitlab::Ci::Pipeline::Seed::Deployment.new(build).to_resource
      build.save!
      build
    end
  end
end
