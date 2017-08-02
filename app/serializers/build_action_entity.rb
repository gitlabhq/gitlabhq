class BuildActionEntity < Grape::Entity
  include RequestAwareEntity

  expose :name do |build|
    build.name
  end

  expose :path do |build|
    play_project_job_path(build.project, build)
  end

  expose :playable?, as: :playable

  private

  alias_method :build, :object

  def playable?
    build.playable? && can?(request.current_user, :update_build, build)
  end
end
