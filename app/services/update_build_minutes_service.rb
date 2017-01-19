class UpdateBuildMinutesService < BaseService
  def execute(build)
    return unless build.shared_runners_minutes_limit_enabled?
    return unless build.complete?
    return unless build.duration

    ProjectStatistics.update_counters(project_statistics,
      shared_runners_seconds: build.duration)

    NamespaceStatistics.update_counters(namespace_statistics,
      shared_runners_seconds: build.duration)
  end

  private

  def namespace_statistics
    namespace.namespace_statistics || namespace.create_namespace_statistics
  end

  def project_statistics
    project.statistics || project.create_statistics(namespace: namespace)
  end

  def namespace
    project.namespace
  end
end
