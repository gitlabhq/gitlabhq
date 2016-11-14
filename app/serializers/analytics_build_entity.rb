class AnalyticsBuildEntity < Grape::Entity
  include RequestAwareEntity

  expose :name
  expose :ref, as: :branch
  expose :short_sha
  expose :started_at, as: :date
  expose :duration, as: :total_time

  expose :url do |build|
    url_to(:namespace_project_build, build)
  end

  expose :branch_url do |build|
    url_to(:namespace_project_tree, build, build.ref)
  end

  expose :commit_url do |build|
    url_to(:namespace_project_commit, build, build.sha)
  end

  private

  def url_to(route, build, id = nil)
    public_send("#{route}_url", build.project.namespace, build.project, id || build)
  end
end
