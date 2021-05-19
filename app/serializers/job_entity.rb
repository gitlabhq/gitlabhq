# frozen_string_literal: true

class JobEntity < Grape::Entity
  include RequestAwareEntity

  expose :id
  expose :name

  expose :started?, as: :started
  expose :complete?, as: :complete
  expose :archived?, as: :archived

  # bridge jobs don't have build detail pages
  expose :build_path, if: ->(build) { !build.is_a?(Ci::Bridge) } do |build|
    build_path(build)
  end

  expose :retry_path, if: -> (*) { retryable? } do |build|
    path_to(:retry_namespace_project_job, build)
  end

  expose :cancel_path, if: -> (*) { cancelable? } do |build|
    path_to(
      :cancel_namespace_project_job,
      build,
      { continue: { to: build_path(build) } }
    )
  end

  expose :play_path, if: -> (*) { playable? } do |build|
    path_to(:play_namespace_project_job, build)
  end

  expose :unschedule_path, if: -> (*) { scheduled? } do |build|
    path_to(:unschedule_namespace_project_job, build)
  end

  expose :playable?, as: :playable
  expose :scheduled?, as: :scheduled
  expose :scheduled_at, if: -> (*) { scheduled? }
  expose :created_at
  expose :updated_at
  expose :detailed_status, as: :status, with: DetailedStatusEntity
  expose :callout_message, if: -> (*) { failed? && !build.script_failure? }
  expose :recoverable, if: -> (*) { failed? }

  private

  alias_method :build, :object

  def cancelable?
    build.cancelable? && can?(request.current_user, :update_build, build)
  end

  def retryable?
    build.retryable? && can?(request.current_user, :update_build, build)
  end

  def playable?
    build.playable? && can?(request.current_user, :update_build, build)
  end

  def scheduled?
    build.scheduled?
  end

  def detailed_status
    build.detailed_status(request.current_user)
  end

  def path_to(route, build, params = {})
    send("#{route}_path", build.project.namespace, build.project, build, params) # rubocop:disable GitlabSecurity/PublicSend
  end

  def build_path(build)
    build.target_url || path_to(:namespace_project_job, build)
  end

  def failed?
    build.failed?
  end

  def callout_message
    build_presenter.callout_failure_message
  end

  def recoverable
    build_presenter.recoverable?
  end

  def build_presenter
    @build_presenter ||= build.present
  end
end
