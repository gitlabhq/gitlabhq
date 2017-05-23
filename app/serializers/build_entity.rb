class BuildEntity < Grape::Entity
  include RequestAwareEntity

  expose :id, :name
  expose :created_at, :updated_at
  expose :queued_at, :started_at, :finished_at

  expose :build_path do |build|
    path_to(:namespace_project_build, build)
  end

  expose :retry_path do |build|
    path_to(:retry_namespace_project_build, build)
  end

  expose :play_path, if: -> (*) { playable? } do |build|
    path_to(:play_namespace_project_build, build)
  end

  expose :playable?, as: :playable
  expose :detailed_status, as: :status, with: StatusEntity
  expose :tag_list, as: :tags
  expose :artifacts, using: BuildArtifactEntity

  private

  alias_method :build, :object

  def playable?
    build.playable? && can?(request.current_user, :update_build, build)
  end

  def detailed_status
    build.detailed_status(request.current_user)
  end

  def path_to(route, build)
    send("#{route}_path", build.project.namespace, build.project, build)
  end
end
