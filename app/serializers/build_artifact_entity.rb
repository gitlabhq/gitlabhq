class BuildArtifactEntity < Grape::Entity
  include RequestAwareEntity

  expose :name do |build|
    build.name
  end

  expose :path do |build|
    download_namespace_project_build_artifacts_path(
      build.project.namespace,
      build.project,
      build)
  end

  expose :codeclimate?, as: :codeclimate
end
