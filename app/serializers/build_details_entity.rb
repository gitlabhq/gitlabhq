class BuildDetailsEntity < BuildEntity
  expose :coverage, :erased_at, :duration
  expose :tag_list, as: :tags

  expose :artifacts, using: BuildArtifactEntity
  expose :runner, using: RunnerEntity
  expose :pipeline, using: PipelineEntity

  expose :merge_request_path do |build|
    merge_request = build.merge_request
    project = build.project

    if merge_request.nil? || !can?(request.current_user, :read_merge_request, project)
      nil
    else
      namespace_project_merge_request_path(project.namespace, project, merge_request)
    end
  end

  expose :new_issue_path do |build|
    project = build.project

    unless build.failed? && can?(request.current_user, :create_issue, project)
      nil
    else
      new_namespace_project_issue_path(project.namespace, project)
    end
  end

  expose :raw_path do |build|
    project = build.project
    raw_namespace_project_build_path(project.namespace, project, build)
  end
end
