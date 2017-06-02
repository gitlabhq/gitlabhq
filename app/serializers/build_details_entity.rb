class BuildDetailsEntity < BuildEntity
  expose :coverage, :erased_at, :duration
  expose :tag_list, as: :tags

  expose :user, using: UserEntity

  expose :erased_by, if: -> (*) { build.erased? }, using: UserEntity
  expose :erase_path, if: -> (*) { build.erasable? && can?(current_user, :update_build, project) } do |build|
    erase_namespace_project_job_path(project.namespace, project, build)
  end

  expose :artifacts, using: BuildArtifactEntity
  expose :runner, using: RunnerEntity
  expose :pipeline, using: PipelineEntity

  expose :merge_request, if: -> (*) { can?(current_user, :read_merge_request, build.merge_request) } do
    expose :iid do |build|
      build.merge_request.iid
    end

    expose :path do |build|
      namespace_project_merge_request_path(project.namespace, project, build.merge_request)
    end
  end

  expose :new_issue_path, if: -> (*) { can?(request.current_user, :create_issue, project) && build.failed? } do |build|
    new_namespace_project_issue_path(project.namespace, project, issue: build_failed_issue_options)
  end

  expose :raw_path do |build|
    raw_namespace_project_build_path(project.namespace, project, build)
  end

  private

  def build_failed_issue_options
    {
      title: "Build Failed ##{build.id}",
      description: namespace_project_job_url(project.namespace, project, build)
    }
  end

  def current_user
    request.current_user
  end

  def project
    build.project
  end
end
