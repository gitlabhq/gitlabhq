class BuildSuccessWorker
  include Sidekiq::Worker
  sidekiq_options queue: :default

  def perform(build_id)
    Ci::Build.find_by(id: build_id).try do |build|
      return unless build.project

      create_deployment(build)
    end
  end

  private

  def create_deployment(build)
    return if build.environment.blank?

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
