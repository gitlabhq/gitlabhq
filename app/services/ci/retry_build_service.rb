# frozen_string_literal: true

module Ci
  class RetryBuildService < ::BaseService
    include Gitlab::Utils::StrongMemoize

    def self.clone_accessors
      %i[pipeline project ref tag options name
         allow_failure stage stage_id stage_idx trigger_request
         yaml_variables when environment coverage_regex
         description tag_list protected needs_attributes
         job_variables_attributes resource_group scheduling_type].freeze
    end

    def self.extra_accessors
      []
    end

    def execute(build)
      build.ensure_scheduling_type!

      clone!(build).tap do |new_build|
        check_assignable_runners!(new_build)
        next if new_build.failed?

        Gitlab::OptimisticLocking.retry_lock(new_build, name: 'retry_build', &:enqueue)
        AfterRequeueJobService.new(project, current_user).execute(build)
      end
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def clone!(build)
      # Cloning a build requires a strict type check to ensure
      # the attributes being used for the clone are taken straight
      # from the model and not overridden by other abstractions.
      raise TypeError unless build.instance_of?(Ci::Build)

      check_access!(build)

      new_build = clone_build(build)

      new_build.run_after_commit do
        ::MergeRequests::AddTodoWhenBuildFailsService
          .new(project: project)
          .close(new_build)
      end

      if create_deployment_in_separate_transaction?
        new_build.run_after_commit do |new_build|
          ::Deployments::CreateForBuildService.new.execute(new_build)
        end
      end

      ::Ci::Pipelines::AddJobService.new(build.pipeline).execute!(new_build) do |job|
        BulkInsertableAssociations.with_bulk_insert do
          job.save!
        end
      end

      build.reset # refresh the data to get new values of `retried` and `processed`.

      new_build
    end
    # rubocop: enable CodeReuse/ActiveRecord

    private

    def check_access!(build)
      unless can?(current_user, :update_build, build)
        raise Gitlab::Access::AccessDeniedError
      end
    end

    def check_assignable_runners!(build); end

    def clone_build(build)
      project.builds.new(build_attributes(build)).tap do |new_build|
        unless create_deployment_in_separate_transaction?
          new_build.assign_attributes(deployment_attributes_for(new_build, build))
        end
      end
    end

    def build_attributes(build)
      attributes = self.class.clone_accessors.to_h do |attribute|
        [attribute, build.public_send(attribute)] # rubocop:disable GitlabSecurity/PublicSend
      end

      if create_deployment_in_separate_transaction? && build.persisted_environment.present?
        attributes[:metadata_attributes] ||= {}
        attributes[:metadata_attributes][:expanded_environment_name] = build.expanded_environment_name
      end

      attributes[:user] = current_user
      attributes
    end

    def deployment_attributes_for(new_build, old_build)
      ::Gitlab::Ci::Pipeline::Seed::Build
        .deployment_attributes_for(new_build, old_build.persisted_environment)
    end

    def create_deployment_in_separate_transaction?
      strong_memoize(:create_deployment_in_separate_transaction) do
        ::Feature.enabled?(:create_deployment_in_separate_transaction, project, default_enabled: :yaml)
      end
    end
  end
end

Ci::RetryBuildService.prepend_mod_with('Ci::RetryBuildService')
