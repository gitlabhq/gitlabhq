class BuildEntity < Grape::Entity
  include RequestAwareEntity

  expose :id
  expose :name

  expose :build_url do |build|
    @urls.namespace_project_build_url(
      build.project.namespace,
      build.project,
      build)
  end

  expose :retry_url do |build|
    @urls.retry_namespace_project_build_url(
      build.project.namespace,
      build.project,
      build)
  end
end
