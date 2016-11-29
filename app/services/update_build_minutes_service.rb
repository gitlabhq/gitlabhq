class UpdateBuildMinutesService < BaseService
  def execute(build)
    return unless build.runner
    return unless build.runner.shared?
    return unless build.duration

    project.find_or_create_project_metrics.
      update_all('shared_runners_minutes = shared_runners_minutes + ?', build.duration)
  end
end
