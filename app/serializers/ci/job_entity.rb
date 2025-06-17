# frozen_string_literal: true

module Ci
  class JobEntity < Grape::Entity
    include RequestAwareEntity

    expose :id
    expose :name
    expose :test_suite_name

    expose :started?, as: :started
    expose :started_at, if: ->(job) { job.started? }
    expose :complete?, as: :complete
    expose :archived?, as: :archived
    expose :source, if: ->(job, options) { job.is_a?(Ci::Build) && options[:enable_source] }

    # bridge jobs don't have build details pages
    expose :build_path, if: ->(job) { !job.is_a?(Ci::Bridge) } do |job|
      job_path(job)
    end

    expose :retry_path, if: ->(*) { retryable? } do |job|
      path_to(:retry_namespace_project_job, job)
    end

    expose :cancel_path, if: ->(*) { cancelable? } do |job|
      path_to(
        :cancel_namespace_project_job,
        job,
        { continue: { to: job_path(job) } }
      )
    end

    expose :force_cancel_path, if: ->(*) { force_cancelable? } do |job|
      path_to(
        :cancel_namespace_project_job,
        job,
        { continue: { to: job_path(job) }, force: true }
      )
    end

    expose :play_path, if: ->(*) { playable? } do |job|
      path_to(:play_namespace_project_job, job)
    end

    expose :unschedule_path, if: ->(*) { scheduled? } do |job|
      path_to(:unschedule_namespace_project_job, job)
    end

    expose :playable?, as: :playable
    expose :scheduled?, as: :scheduled
    expose :scheduled_at, if: ->(*) { scheduled? }
    expose :created_at
    expose :queued_at
    expose :queued_duration
    expose :updated_at
    expose :detailed_status, as: :status, with: DetailedStatusEntity
    expose :callout_message, if: ->(*) { failed? && !job.script_failure? }
    expose :recoverable, if: ->(*) { failed? }

    private

    alias_method :job, :object

    def cancelable?
      job.cancelable? && can?(request.current_user, :cancel_build, job)
    end

    def authorized_to_force_cancel?
      can?(request.current_user, :cancel_build, job) && can?(request.current_user, :maintainer_access, job)
    end

    def force_cancelable?
      job.force_cancelable? && authorized_to_force_cancel?
    end

    def retryable?
      job.retryable? && can?(request.current_user, :update_build, job)
    end

    def playable?
      job.playable? && can?(request.current_user, :update_build, job)
    end

    def scheduled?
      job.scheduled?
    end

    def detailed_status
      job.detailed_status(request.current_user)
    end

    def path_to(route, job, params = {})
      # rubocop:disable GitlabSecurity/PublicSend -- needs send
      send("#{route}_path", job.project.namespace, job.project, job, params)
      # rubocop:enable GitlabSecurity/PublicSend
    end

    def job_path(job)
      job.target_url || path_to(:namespace_project_job, job)
    end

    def failed?
      job.failed?
    end

    def callout_message
      job_presenter.callout_failure_message
    end

    def recoverable
      job_presenter.recoverable?
    end

    def job_presenter
      @job_presenter ||= job.present
    end
  end
end
