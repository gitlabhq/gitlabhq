class BuildDetailsEntity < JobEntity
  expose :coverage, :erased_at, :duration
  expose :tag_list, as: :tags
  expose :user, using: UserEntity
  expose :runner, using: RunnerEntity
  expose :pipeline, using: PipelineEntity

  expose :erased_by, if: -> (*) { build.erased? }, using: UserEntity
  expose :erase_path, if: -> (*) { build.erasable? && can?(current_user, :erase_build, build) } do |build|
    erase_project_job_path(project, build)
  end

  expose :merge_request, if: -> (*) { can?(current_user, :read_merge_request, build.merge_request) } do
    expose :iid do |build|
      build.merge_request.iid
    end

    expose :path do |build|
      project_merge_request_path(build.merge_request.project,
                                 build.merge_request)
    end
  end

  expose :new_issue_path, if: -> (*) { can?(request.current_user, :create_issue, project) && build.failed? } do |build|
    new_project_issue_path(project, issue: build_failed_issue_options)
  end

  expose :raw_path do |build|
    raw_project_job_path(project, build)
  end

  private

  def build_failed_issue_options
    { title: "Job Failed ##{build.id}",
      description: "Job [##{build.id}](#{project_job_path(project, build)}) failed for #{build.sha}:\n" }
  end

  def current_user
    request.current_user
  end

  def project
    build.project
  end
end
