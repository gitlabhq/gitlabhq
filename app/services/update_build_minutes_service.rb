class UpdateBuildMinutesService < BaseService
  def execute(build)
    return unless build.shared_runners_minutes_limit_enabled?
    return unless build.complete?
    return unless build.duration

    ProjectMetrics.update_counters(project_metrics,
      shared_runners_minutes: build.duration)

    NamespaceMetrics.update_counters(namespace_metrics,
      shared_runners_minutes: build.duration)
  end

  private

  def namespace_metrics
    namespace.namespace_metrics || namespace.create_namespace_metrics
  end

  def project_metrics
    project.project_metrics || project.create_project_metrics
  end

  def namespace
    project.namespace
  end
end
