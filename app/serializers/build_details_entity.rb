# frozen_string_literal: true

class BuildDetailsEntity < JobEntity
  include EnvironmentHelper
  include RequestAwareEntity
  include CiStatusHelper

  expose :coverage, :erased_at, :duration
  expose :tag_list, as: :tags
  expose :user, using: UserEntity
  expose :runner, using: RunnerEntity
  expose :pipeline, using: PipelineEntity

  expose :deployment_status, if: -> (*) { build.has_environment? } do
    expose :deployment_status, as: :status

    expose :icon do |build|
      ci_label_for_status(build.status)
    end

    expose :persisted_environment, as: :environment, with: EnvironmentEntity
  end

  expose :metadata, using: BuildMetadataEntity

  expose :artifact, if: -> (*) { can?(current_user, :read_build, build) } do
    expose :download_path, if: -> (*) { build.artifacts? } do |build|
      download_project_job_artifacts_path(project, build)
    end

    expose :browse_path, if: -> (*) { build.browsable_artifacts? } do |build|
      browse_project_job_artifacts_path(project, build)
    end

    expose :keep_path, if: -> (*) { build.has_expiring_artifacts? && can?(current_user, :update_build, build) } do |build|
      keep_project_job_artifacts_path(project, build)
    end

    expose :expire_at, if: -> (*) { build.artifacts_expire_at.present? } do |build|
      build.artifacts_expire_at
    end

    expose :expired, if: -> (*) { build.artifacts_expire_at.present? } do |build|
      build.artifacts_expired?
    end
  end

  expose :erased_by, if: -> (*) { build.erased? }, using: UserEntity
  expose :erase_path, if: -> (*) { build.erasable? && can?(current_user, :erase_build, build) } do |build|
    erase_project_job_path(project, build)
  end

  expose :terminal_path, if: -> (*) { can_create_build_terminal? } do |build|
    terminal_project_job_path(project, build)
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

  expose :trigger, if: -> (*) { build.trigger_request } do
    expose :trigger_short_token, as: :short_token

    expose :trigger_variables, as: :variables, using: TriggerVariableEntity
  end

  private

  def build_failed_issue_options
    { title: "Job Failed ##{build.id}",
      description: "Job [##{build.id}](#{project_job_url(project, build)}) failed for #{build.sha}:\n" }
  end

  def current_user
    request.current_user
  end

  def project
    build.project
  end

  def can_create_build_terminal?
    can?(current_user, :create_build_terminal, build) && build.has_terminal?
  end
end
