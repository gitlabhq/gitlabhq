class UpdateBuildMinutesService < BaseService
  def execute(build)
    return unless build.runner
    return unless build.runner.shared?
    return unless build.duration
    return unless build.project
    return if build.project.public?

    namespace = project.namespace
    return unless namespace

    namespace.find_or_create_project_metrics.
      update_all('shared_runners_minutes = shared_runners_minutes + ?', build.duration)
  end
end
