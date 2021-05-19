# frozen_string_literal: true

module Ci
  class RetryBuildService < ::BaseService
    def self.clone_accessors
      %i[pipeline project ref tag options name
         allow_failure stage stage_id stage_idx trigger_request
         yaml_variables when environment coverage_regex
         description tag_list protected needs_attributes
         resource_group scheduling_type].freeze
    end

    def execute(build)
      build.ensure_scheduling_type!

      reprocess!(build).tap do |new_build|
        Gitlab::OptimisticLocking.retry_lock(new_build, name: 'retry_build', &:enqueue)
        AfterRequeueJobService.new(project, current_user).execute(build)

        ::MergeRequests::AddTodoWhenBuildFailsService
          .new(project: project, current_user: current_user)
          .close(new_build)
      end
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def reprocess!(build)
      check_access!(build)

      attributes = self.class.clone_accessors.to_h do |attribute|
        [attribute, build.public_send(attribute)] # rubocop:disable GitlabSecurity/PublicSend
      end

      attributes[:user] = current_user

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

    def check_access!(build)
      unless can?(current_user, :update_build, build)
        raise Gitlab::Access::AccessDeniedError
      end
    end

    def create_build!(attributes)
      build = project.builds.new(attributes)
      build.assign_attributes(::Gitlab::Ci::Pipeline::Seed::Build.environment_attributes_for(build))
      build.retried = false
      BulkInsertableAssociations.with_bulk_insert do
        build.save!
      end
      build
    end
  end
end

Ci::RetryBuildService.prepend_mod_with('Ci::RetryBuildService')
