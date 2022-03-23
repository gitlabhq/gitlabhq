# frozen_string_literal: true

module Ci
  class RetryJobService < ::BaseService
    include Gitlab::Utils::StrongMemoize

    def execute(job)
      if job.retryable?
        job.ensure_scheduling_type!
        new_job = retry_job(job)

        ServiceResponse.success(payload: { job: new_job })
      else
        ServiceResponse.error(
          message: 'Job cannot be retried',
          payload: { job: job, reason: :not_retryable }
        )
      end
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def clone!(job)
      # Cloning a job requires a strict type check to ensure
      # the attributes being used for the clone are taken straight
      # from the model and not overridden by other abstractions.
      raise TypeError unless job.instance_of?(Ci::Build)

      check_access!(job)

      new_job = clone_job(job)

      new_job.run_after_commit do
        ::Ci::CopyCrossDatabaseAssociationsService.new.execute(job, new_job)

        ::Deployments::CreateForBuildService.new.execute(new_job)

        ::MergeRequests::AddTodoWhenBuildFailsService
          .new(project: project)
          .close(new_job)
      end

      ::Ci::Pipelines::AddJobService.new(job.pipeline).execute!(new_job) do |processable|
        BulkInsertableAssociations.with_bulk_insert do
          processable.save!
        end
      end

      job.reset # refresh the data to get new values of `retried` and `processed`.

      new_job
    end
    # rubocop: enable CodeReuse/ActiveRecord

    private

    def retry_job(job)
      clone!(job).tap do |new_job|
        check_assignable_runners!(new_job)
        next if new_job.failed?

        Gitlab::OptimisticLocking.retry_lock(new_job, name: 'retry_build', &:enqueue)
        AfterRequeueJobService.new(project, current_user).execute(job)
      end
    end

    def check_access!(job)
      unless can?(current_user, :update_build, job)
        raise Gitlab::Access::AccessDeniedError, '403 Forbidden'
      end
    end

    def check_assignable_runners!(job); end

    def clone_job(job)
      project.builds.new(job_attributes(job))
    end

    def job_attributes(job)
      attributes = job.class.clone_accessors.to_h do |attribute|
        [attribute, job.public_send(attribute)] # rubocop:disable GitlabSecurity/PublicSend
      end

      if job.persisted_environment.present?
        attributes[:metadata_attributes] ||= {}
        attributes[:metadata_attributes][:expanded_environment_name] = job.expanded_environment_name
      end

      attributes[:user] = current_user
      attributes
    end
  end
end

Ci::RetryJobService.prepend_mod_with('Ci::RetryJobService')
