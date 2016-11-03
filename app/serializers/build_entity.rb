class BuildEntity < Grape::Entity
  include RequestAwareEntity

  expose :id
  expose :name

  expose :build_url do |build|
    url_to(:namespace_project_build, build)
  end

  expose :retry_url do |build|
    url_to(:retry_namespace_project_build, build)
  end

  expose :play_url, if: ->(build, _) { build.manual? } do |build|
    url_to(:play_namespace_project_build, build)
  end

  private

  def url_to(route, build)
    @urls.send("#{route}_url", build.project.namespace, build.project, build)
  end
end
