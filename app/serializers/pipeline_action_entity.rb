class PipelineActionEntity < Grape::Entity
  include RequestAwareEntity

  expose :name do |build|
    build.name.humanize
  end

  expose :url do |build|
    play_namespace_project_build_path(
      build.project.namespace,
      build.project,
      build)
  end
end
