class BuildSuccessWorker
  include Sidekiq::Worker
  include BuildQueue

  def perform(build_id)
    Ci::Build.find_by(id: build_id).try do |build|
      create_deployment(build) if build.environment.present?
    end
  end

  private

  def create_deployment(build)
    service = CreateDeploymentService.new(
      build.project, build.user,
      environment: build.environment,
      sha: build.sha,
      ref: build.ref,
      tag: build.tag,
      options: build.options.to_h[:environment],
      variables: build.variables)

    service.execute(build)
  end
end
