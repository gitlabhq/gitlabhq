class JobEntity < Grape::Entity
  include RequestAwareEntity

  expose :id
  expose :name

  expose :started?, as: :started

  expose :build_path do |build|
    build.target_url || path_to(:namespace_project_job, build)
  end

  expose :retry_path, if: -> (*) { retryable? } do |build|
    path_to(:retry_namespace_project_job, build)
  end

  expose :cancel_path, if: -> (*) { cancelable? } do |build|
    path_to(:cancel_namespace_project_job, build)
  end

  expose :play_path, if: -> (*) { playable? } do |build|
    path_to(:play_namespace_project_job, build)
  end

  expose :playable?, as: :playable
  expose :created_at
  expose :updated_at
  expose :status do
    expose :callout_message, if: -> (*) { failed_or_allowed_to_fail? }
    expose :retry_button, if: -> (*) { failed_or_allowed_to_fail? }
    expose :detailed_status, merge: true, as: :status, with: StatusEntity
  end

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

  def detailed_status
    build.detailed_status(request.current_user)
  end

  def failed_or_allowed_to_fail?
    build.failed? || build.allow_failure?
  end

  def callout_message
    build_presenter.callout_failure_message
  end

  def retry_button
    build_presenter.show_retry_button?
  end

  def build_presenter
    @build_presenter ||= Ci::BuildPresenter.new(build)
  end

  def path_to(route, build)
    send("#{route}_path", build.project.namespace, build.project, build) # rubocop:disable GitlabSecurity/PublicSend
  end
end
