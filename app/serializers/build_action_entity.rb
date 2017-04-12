class BuildActionEntity < Grape::Entity
  include RequestAwareEntity

  expose :name do |build|
    build.name
  end

  expose :path do |build|
    play_namespace_project_build_path(
      build.project.namespace,
      build.project,
      build)
  end

  expose :playable?, as: :playable

  private

  alias_method :build, :object

  def playable?
    can?(request.user, :play_build, build) && build.playable?
  end
end
