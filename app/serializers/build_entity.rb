class BuildEntity < Grape::Entity
  include RequestAwareEntity

  expose :id
  expose :name

  expose :build_path do |build|
    path_to(:namespace_project_build, build)
  end

  expose :retry_path do |build|
    path_to(:retry_namespace_project_build, build)
  end

  expose :play_path, if: ->(build, _) { build.manual? } do |build|
    path_to(:play_namespace_project_build, build)
  end

  private

  def path_to(route, build)
    send("#{route}_path", build.project.namespace, build.project, build)
  end
end
