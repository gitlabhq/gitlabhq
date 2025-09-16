# frozen_string_literal: true

class BuildDetailsEntity < Ci::JobEntity
  expose :coverage, :erased_at, :finished_at, :duration
  expose :tag_list, as: :tags
  expose :has_trace?, as: :has_trace
  expose :stage_name, as: :stage
  expose :stuck?, as: :stuck
  expose :user, using: UserEntity
  expose :runner, using: RunnerEntity
  expose :pipeline, using: Ci::PipelineEntity

  expose :metadata do
    expose :timeout_human_readable_value, as: :timeout_human_readable
    expose :timeout_human_readable_source, as: :timeout_source
  end

  expose :deployment_status, if: ->(*) { build.deployment_job? } do
    expose :deployment_status, as: :status
    expose :persisted_environment, as: :environment do |build, options|
      options.merge(deployment_details: false).then do |opts|
        EnvironmentEntity.represent(build.persisted_environment, opts)
      end
    end
  end

  expose :deployment_cluster, if: ->(build) { build&.deployment&.cluster } do |build, options|
    # Until data is copied over from deployments.cluster_id, this entity must represent Deployment instead of DeploymentCluster
    # https://gitlab.com/gitlab-org/gitlab/issues/202628
    DeploymentClusterEntity.represent(build.deployment, options)
  end

  expose :artifact, if: ->(*) { can?(current_user, :read_job_artifacts, build) } do
    expose :download_path, if: ->(*) { build.locked_artifacts? || build.artifacts? } do |build|
      fast_download_project_job_artifacts_path(project, build)
    end

    expose :browse_path, if: ->(*) { build.locked_artifacts? || build.browsable_artifacts? } do |build|
      fast_browse_project_job_artifacts_path(project, build)
    end

    expose :keep_path, if: ->(*) { (build.has_expired_locked_archive_artifacts? || build.has_expiring_archive_artifacts?) && can?(current_user, :keep_job_artifacts, build) } do |build|
      fast_keep_project_job_artifacts_path(project, build)
    end

    expose :expire_at, if: ->(*) { build.artifacts_expire_at.present? } do |build|
      build.artifacts_expire_at
    end

    expose :expired, if: ->(*) { build.artifacts_expire_at.present? } do |build|
      build.artifacts_expired?
    end

    expose :locked do |build|
      build.pipeline.artifacts_locked?
    end
  end

  expose :report_artifacts,
    as: :reports,
    using: JobArtifactReportEntity,
    if: ->(*) { can?(current_user, :read_build, build) }

  expose :job_annotations,
    as: :annotations,
    using: Ci::JobAnnotationEntity

  expose :erased_by, if: ->(*) { build.erased? }, using: UserEntity
  expose :erase_path, if: ->(*) { build.erasable? && can?(current_user, :erase_build, build) } do |build|
    erase_project_job_path(project, build)
  end

  expose :failure_reason, if: ->(*) { build.failed? }

  expose :terminal_path, if: ->(*) { can_create_build_terminal? } do |build|
    terminal_project_job_path(project, build)
  end

  expose :merge_request, if: ->(*) { can?(current_user, :read_merge_request, build.merge_request) } do
    expose :iid do |build|
      build.merge_request.iid
    end

    expose :path do |build|
      project_merge_request_path(build.merge_request.project, build.merge_request)
    end
  end

  expose :new_issue_path, if: ->(*) { can?(request.current_user, :create_issue, project) && build.failed? } do |build|
    new_project_issue_path(project, issue: build_failed_issue_options)
  end

  expose :raw_path do |build|
    raw_project_job_path(project, build)
  end

  expose :trigger, if: ->(*) { build.pipeline.trigger_id } do
    expose :trigger_short_token, as: :short_token

    expose :trigger_variables, as: :variables, using: TriggerVariableEntity
  end

  expose :runners do
    expose :online do |build|
      build.any_runners_online?
    end

    expose :available do |build|
      build.any_runners_available?
    end

    expose :settings_path, if: ->(*) { can_admin_build? } do |build|
      project_runners_path(project)
    end
  end

  private

  alias_method :build, :object

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

  def can_admin_build?
    can?(request.current_user, :admin_build, project)
  end

  def callout_message
    return super unless build.failure_reason.to_sym == :missing_dependency_failure

    docs_url = "https://docs.gitlab.com/ee/ci/yaml/#dependencies"
    troubleshooting_url = "https://docs.gitlab.com/ee/ci/jobs/job_artifacts_troubleshooting.html#error-message-this-job-could-not-start-because-it-could-not-retrieve-the-needed-artifacts"

    [
      failure_message,
      help_message(docs_url, troubleshooting_url).html_safe
    ].join("<br />")
  end

  def invalid_dependencies
    build.invalid_dependencies.map(&:name).join(', ')
  end

  def failure_message
    # We do not return the invalid_dependencies for all scenarios see https://gitlab.com/gitlab-org/gitlab/-/issues/287772#note_914406387
    punctuation = invalid_dependencies.empty? ? '.' : ': '
    _("This job could not start because it could not retrieve the needed artifacts%{punctuation}%{invalid_dependencies}") %
      { invalid_dependencies: ERB::Util.html_escape(invalid_dependencies), punctuation: punctuation }
  end

  def help_message(docs_url, troubleshooting_url)
    ERB::Util.html_escape(_("Learn more about <a href=\"#{docs_url}\">dependencies</a> and <a href=\"#{troubleshooting_url}\">common causes</a> of this error.</a>".html_safe))
  end

  def timeout_human_readable_source
    return unless build.timeout_source_value

    source = build.timeout_source_value.split('_').first
    source == 'unknown' ? build.timeout_source_value : source
  end
end

BuildDetailsEntity.prepend_mod_with('BuildDetailEntity')
