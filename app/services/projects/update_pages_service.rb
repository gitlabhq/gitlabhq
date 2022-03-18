# frozen_string_literal: true

module Projects
  class UpdatePagesService < BaseService
    InvalidStateError = Class.new(StandardError)
    BLOCK_SIZE = 32.kilobytes
    PUBLIC_DIR = 'public'

    # old deployment can be cached by pages daemon
    # so we need to give pages daemon some time update cache
    # 10 minutes is enough, but 30 feels safer
    OLD_DEPLOYMENTS_DESTRUCTION_DELAY = 30.minutes.freeze

    attr_reader :build

    def initialize(project, build)
      @project = project
      @build = build
    end

    def execute
      register_attempt

      # Create status notifying the deployment of pages
      @commit_status = build_commit_status
      ::Ci::Pipelines::AddJobService.new(@build.pipeline).execute!(@commit_status) do |job|
        job.enqueue!
        job.run!
      end

      validate_state!
      validate_max_size!
      validate_max_entries!

      build.artifacts_file.use_file do |artifacts_path|
        create_pages_deployment(artifacts_path, build)
        success
      end
    rescue InvalidStateError => e
      error(e.message)
    rescue StandardError => e
      error(e.message)
      raise e
    end

    private

    def success
      @commit_status.success
      @project.mark_pages_as_deployed
      super
    end

    def error(message)
      register_failure
      log_error("Projects::UpdatePagesService: #{message}")
      @commit_status.allow_failure = !latest?
      @commit_status.description = message
      @commit_status.drop(:script_failure)
      super
    end

    def build_commit_status
      GenericCommitStatus.new(
        user: build.user,
        stage: 'deploy',
        name: 'pages:deploy'
      )
    end

    def create_pages_deployment(artifacts_path, build)
      sha256 = build.job_artifacts_archive.file_sha256

      deployment = nil
      File.open(artifacts_path) do |file|
        deployment = project.pages_deployments.create!(file: file,
                                                       file_count: entries_count,
                                                       file_sha256: sha256,
                                                       ci_build_id: build.id
                                                      )

        validate_outdated_sha!

        project.update_pages_deployment!(deployment)
      end

      DestroyPagesDeploymentsWorker.perform_in(
        OLD_DEPLOYMENTS_DESTRUCTION_DELAY,
        project.id,
        deployment.id
      )
    end

    def ref
      build.ref
    end

    def artifacts
      build.artifacts_file.path
    end

    def latest_sha
      project.commit(build.ref).try(:sha).to_s
    ensure
      # Close any file descriptors that were opened and free libgit2 buffers
      project.cleanup
    end

    def sha
      build.sha
    end

    def register_attempt
      pages_deployments_total_counter.increment
    end

    def register_failure
      pages_deployments_failed_total_counter.increment
    end

    def pages_deployments_total_counter
      @pages_deployments_total_counter ||= Gitlab::Metrics.counter(:pages_deployments_total, "Counter of GitLab Pages deployments triggered")
    end

    def pages_deployments_failed_total_counter
      @pages_deployments_failed_total_counter ||= Gitlab::Metrics.counter(:pages_deployments_failed_total, "Counter of GitLab Pages deployments which failed")
    end

    def validate_state!
      raise InvalidStateError, 'missing pages artifacts' unless build.artifacts?
      raise InvalidStateError, 'missing artifacts metadata' unless build.artifacts_metadata?

      validate_outdated_sha!
    end

    def validate_outdated_sha!
      return if latest?

      # use pipeline_id in case the build is retried
      last_deployed_pipeline_id = project.pages_metadatum&.pages_deployment&.ci_build&.pipeline_id

      return unless last_deployed_pipeline_id
      return if last_deployed_pipeline_id <= build.pipeline_id

      raise InvalidStateError, 'build SHA is outdated for this ref'
    end

    def latest?
      # check if sha for the ref is still the most recent one
      # this helps in case when multiple deployments happens
      sha == latest_sha
    end

    def validate_max_size!
      if total_size > max_size
        raise InvalidStateError, "artifacts for pages are too large: #{total_size}"
      end
    end

    # Calculate page size after extract
    def total_size
      @total_size ||= build.artifacts_metadata_entry(PUBLIC_DIR + '/', recursive: true).total_size
    end

    def max_size_from_settings
      Gitlab::CurrentSettings.max_pages_size.megabytes
    end

    def max_size
      max_pages_size = max_size_from_settings

      return ::Gitlab::Pages::MAX_SIZE if max_pages_size == 0

      max_pages_size
    end

    def validate_max_entries!
      if pages_file_entries_limit > 0 && entries_count > pages_file_entries_limit
        raise InvalidStateError, "pages site contains #{entries_count} file entries, while limit is set to #{pages_file_entries_limit}"
      end
    end

    def entries_count
      # we're using the full archive and pages daemon needs to read it
      # so we want the total count from entries, not only "public/" directory
      # because it better approximates work we need to do before we can serve the site
      @entries_count = build.artifacts_metadata_entry("", recursive: true).entries.count
    end

    def pages_file_entries_limit
      project.actual_limits.pages_file_entries
    end
  end
end

Projects::UpdatePagesService.prepend_mod_with('Projects::UpdatePagesService')
