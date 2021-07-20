# frozen_string_literal: true

module Projects
  class UpdatePagesService < BaseService
    InvalidStateError = Class.new(StandardError)
    FailedToExtractError = Class.new(StandardError)
    ExclusiveLeaseTaken = Class.new(StandardError)

    include ::Pages::LegacyStorageLease

    BLOCK_SIZE = 32.kilobytes
    PUBLIC_DIR = 'public'

    # this has to be invalid group name,
    # as it shares the namespace with groups
    TMP_EXTRACT_PATH = '@pages.tmp'

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
      @status = build_commit_status
      ::Ci::Pipelines::AddJobService.new(@build.pipeline).execute!(@status) do |job|
        job.enqueue!
        job.run!
      end

      raise InvalidStateError, 'missing pages artifacts' unless build.artifacts?
      raise InvalidStateError, 'build SHA is outdated for this ref' unless latest?

      build.artifacts_file.use_file do |artifacts_path|
        deploy_to_legacy_storage(artifacts_path)

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
      @status.success
      @project.mark_pages_as_deployed(artifacts_archive: build.job_artifacts_archive)
      super
    end

    def error(message)
      register_failure
      log_error("Projects::UpdatePagesService: #{message}")
      @status.allow_failure = !latest?
      @status.description = message
      @status.drop(:script_failure)
      super
    end

    def build_commit_status
      GenericCommitStatus.new(
        user: build.user,
        stage: 'deploy',
        name: 'pages:deploy'
      )
    end

    def deploy_to_legacy_storage(artifacts_path)
      # path today used by one project can later be used by another
      # so we can't really scope this feature flag by project or group
      return unless ::Settings.pages.local_store.enabled

      return if Feature.enabled?(:skip_pages_deploy_to_legacy_storage, project, default_enabled: :yaml)

      # Create temporary directory in which we will extract the artifacts
      make_secure_tmp_dir(tmp_path) do |tmp_path|
        extract_archive!(artifacts_path, tmp_path)

        # Check if we did extract public directory
        archive_public_path = File.join(tmp_path, PUBLIC_DIR)
        raise InvalidStateError, 'pages miss the public folder' unless Dir.exist?(archive_public_path)
        raise InvalidStateError, 'build SHA is outdated for this ref' unless latest?

        deploy_page!(archive_public_path)
      end
    end

    def extract_archive!(artifacts_path, temp_path)
      if artifacts.ends_with?('.zip')
        extract_zip_archive!(artifacts_path, temp_path)
      else
        raise InvalidStateError, 'unsupported artifacts format'
      end
    end

    def extract_zip_archive!(artifacts_path, temp_path)
      raise InvalidStateError, 'missing artifacts metadata' unless build.artifacts_metadata?

      # Calculate page size after extract
      public_entry = build.artifacts_metadata_entry(PUBLIC_DIR + '/', recursive: true)

      if public_entry.total_size > max_size
        raise InvalidStateError, "artifacts for pages are too large: #{public_entry.total_size}"
      end

      SafeZip::Extract.new(artifacts_path)
        .extract(directories: [PUBLIC_DIR], to: temp_path)
    rescue SafeZip::Extract::Error => e
      raise FailedToExtractError, e.message
    end

    def deploy_page!(archive_public_path)
      deployed = try_obtain_lease do
        deploy_page_unsafe!(archive_public_path)
        true
      end

      unless deployed
        raise ExclusiveLeaseTaken, "Failed to deploy pages - other deployment is in progress"
      end
    end

    def deploy_page_unsafe!(archive_public_path)
      # Do atomic move of pages
      # Move and removal may not be atomic, but they are significantly faster then extracting and removal
      # 1. We move deployed public to previous public path (file removal is slow)
      # 2. We move temporary public to be deployed public
      # 3. We remove previous public path
      FileUtils.mkdir_p(pages_path)
      begin
        FileUtils.move(public_path, previous_public_path)
      rescue StandardError
      end
      FileUtils.move(archive_public_path, public_path)
    ensure
      FileUtils.rm_r(previous_public_path, force: true)
    end

    def create_pages_deployment(artifacts_path, build)
      # we're using the full archive and pages daemon needs to read it
      # so we want the total count from entries, not only "public/" directory
      # because it better approximates work we need to do before we can serve the site
      entries_count = build.artifacts_metadata_entry("", recursive: true).entries.count
      sha256 = build.job_artifacts_archive.file_sha256

      deployment = nil
      File.open(artifacts_path) do |file|
        deployment = project.pages_deployments.create!(file: file,
                                                       file_count: entries_count,
                                                       file_sha256: sha256)

        raise InvalidStateError, 'build SHA is outdated for this ref' unless latest?

        project.update_pages_deployment!(deployment)
      end

      DestroyPagesDeploymentsWorker.perform_in(
        OLD_DEPLOYMENTS_DESTRUCTION_DELAY,
        project.id,
        deployment.id
      )
    end

    def latest?
      # check if sha for the ref is still the most recent one
      # this helps in case when multiple deployments happens
      sha == latest_sha
    end

    def blocks
      # Calculate dd parameters: we limit the size of pages
      1 + max_size / BLOCK_SIZE
    end

    def max_size_from_settings
      Gitlab::CurrentSettings.max_pages_size.megabytes
    end

    def max_size
      max_pages_size = max_size_from_settings

      return ::Gitlab::Pages::MAX_SIZE if max_pages_size == 0

      max_pages_size
    end

    def tmp_path
      @tmp_path ||= File.join(::Settings.pages.path, TMP_EXTRACT_PATH)
    end

    def pages_path
      @pages_path ||= project.pages_path
    end

    def public_path
      @public_path ||= File.join(pages_path, PUBLIC_DIR)
    end

    def previous_public_path
      @previous_public_path ||= File.join(pages_path, "#{PUBLIC_DIR}.#{SecureRandom.hex}")
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

    def make_secure_tmp_dir(tmp_path)
      FileUtils.mkdir_p(tmp_path)
      path = Dir.mktmpdir(tmp_dir_prefix, tmp_path)
      begin
        yield(path)
      ensure
        FileUtils.remove_entry_secure(path)
      end
    end

    def tmp_dir_prefix
      "project-#{project.id}-build-#{build.id}-"
    end
  end
end

Projects::UpdatePagesService.prepend_mod_with('Projects::UpdatePagesService')
