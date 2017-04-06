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
    build.playable? && build.can_play?(request.user)
  end
end
