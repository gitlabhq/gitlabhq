class UpdateBuildMinutesService < BaseService
  def execute(build)
    return unless build.runner.try(:shared?)
    return unless build.project.try(:shared_runners_minutes_limit_enabled?)
    return unless build.finished?
    return unless build.duration

    project.find_or_create_project_metrics.
      update_all('shared_runners_minutes = shared_runners_minutes + ?', build.duration)

    project.namespace.find_or_create_namespace_metrics.
      update_all('shared_runners_minutes = shared_runners_minutes + ?', build.duration)
  end
end
