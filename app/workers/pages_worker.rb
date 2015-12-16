class PagesWorker
  include Sidekiq::Worker
  include Gitlab::CurrentSettings

  BLOCK_SIZE = 32.kilobytes
  MAX_SIZE = 1.terabyte

  sidekiq_options queue: :pages, retry: false

  def perform(build_id)
    @build_id = build_id
    return unless valid?

    # Create status notifying the deployment of pages
    @status = GenericCommitStatus.new(
      project: project,
      commit: build.commit,
      user: build.user,
      ref: build.ref,
      stage: 'deploy',
      name: 'pages:deploy'
    )
    @status.run!

    FileUtils.mkdir_p(tmp_path)

    # Calculate dd parameters: we limit the size of pages
    max_size = current_application_settings.max_pages_size.megabytes
    max_size ||= MAX_SIZE
    blocks = 1 + max_size / BLOCK_SIZE

    # Create temporary directory in which we will extract the artifacts
    Dir.mktmpdir(nil, tmp_path) do |temp_path|
      # We manually extract the archive and limit the archive size with dd
      results = Open3.pipeline(%W(gunzip -c #{artifacts}),
                               %W(dd bs=#{BLOCK_SIZE} count=#{blocks}),
                               %W(tar -x -C #{temp_path} public/),
                               err: '/dev/null')
      return unless results.compact.all?(&:success?)

      # Check if we did extract public directory
      temp_public_path = File.join(temp_path, 'public')
      return unless Dir.exists?(temp_public_path)

      FileUtils.mkdir_p(pages_path)

      # Ignore deployment if the HEAD changed when we were extracting the archive
      return unless valid?

      # Do atomic move of pages
      # Move and removal may not be atomic, but they are significantly faster then extracting and removal
      # 1. We move deployed public to previous public path (file removal is slow)
      # 2. We move temporary public to be deployed public
      # 3. We remove previous public path
      FileUtils.move(public_path, previous_public_path, force: true)
      FileUtils.move(temp_public_path, public_path)
      FileUtils.rm_r(previous_public_path, force: true)

      @status.success
    end
  ensure
    @status.drop if @status && @status.active?
  end

  private

  def valid?
    # check if sha for the ref is still the most recent one
    # this helps in case when multiple deployments happens
    build && build.artifacts_file? && sha == latest_sha
  end

  def build
    @build ||= Ci::Build.find_by(id: @build_id)
  end

  def project
    @project ||= build.project
  end

  def tmp_path
    @tmp_path ||= File.join(Settings.pages.path, 'tmp')
  end

  def pages_path
    @pages_path ||= project.pages_path
  end

  def public_path
    @public_path ||= File.join(pages_path, 'public')
  end

  def previous_public_path
    @previous_public_path ||= File.join(pages_path, "public.#{SecureRandom.hex}")
  end

  def lock_path
    @lock_path ||= File.join(pages_path, 'deploy.lock')
  end

  def ref
    build.ref
  end

  def artifacts
    build.artifacts_file.path
  end

  def latest_sha
    project.commit(build.ref).try(:sha).to_s
  end

  def sha
    build.sha
  end
end
