# frozen_string_literal: true

module Ci
  class RetryBuildService < ::BaseService
    CLONE_ACCESSORS = %i[pipeline project ref tag options name
                         allow_failure stage stage_id stage_idx trigger_request
                         yaml_variables when environment coverage_regex
                         description tag_list protected needs_attributes
                         resource_group scheduling_type].freeze

    def execute(build)
      build.ensure_scheduling_type!

      reprocess!(build).tap do |new_build|
        build.pipeline.mark_as_processable_after_stage(build.stage_idx)

        Gitlab::OptimisticLocking.retry_lock(new_build, &:enqueue)

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
      end.to_h

      attributes[:user] = current_user

      # TODO: we can probably remove this logic
      # see: https://gitlab.com/gitlab-org/gitlab/-/issues/217930
      attributes[:scheduling_type] ||= build.find_legacy_scheduling_type

      Ci::Build.transaction do
        # mark all other builds of that name as retried
        build.pipeline.builds.latest
          .where(name: build.name)
          .update_all(retried: true, processed: true)

        create_build!(attributes).tap do
          # mark existing object as retried/processed without a reload
          build.retried = true
          build.processed = true
        end
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord

    private

    def create_build!(attributes)
      build = project.builds.new(attributes)
      build.assign_attributes(::Gitlab::Ci::Pipeline::Seed::Build.environment_attributes_for(build))
      build.retried = false
      build.save!
      build
    end
  end
end
