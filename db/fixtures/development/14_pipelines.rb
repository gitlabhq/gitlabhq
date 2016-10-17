class Gitlab::Seeder::Pipelines
  STAGES = %w[build test deploy notify]
  BUILDS = [
    { name: 'build:linux', stage: 'build', status: :success },
    { name: 'build:osx', stage: 'build', status: :success },
    { name: 'rspec:linux 0 3', stage: 'test', status: :success },
    { name: 'rspec:linux 1 3', stage: 'test', status: :success },
    { name: 'rspec:linux 2 3', stage: 'test', status: :success },
    { name: 'rspec:windows 0 3', stage: 'test', status: :success },
    { name: 'rspec:windows 1 3', stage: 'test', status: :success },
    { name: 'rspec:windows 2 3', stage: 'test', status: :success },
    { name: 'rspec:windows 2 3', stage: 'test', status: :success },
    { name: 'rspec:osx', stage: 'test', status_event: :success },
    { name: 'spinach:linux', stage: 'test', status: :success },
    { name: 'spinach:osx', stage: 'test', status: :failed, allow_failure: true},
    { name: 'env:alpha', stage: 'deploy', environment: 'alpha', status: :pending },
    { name: 'env:beta', stage: 'deploy', environment: 'beta', status: :running },
    { name: 'env:gamma', stage: 'deploy', environment: 'gamma', status: :canceled },
    { name: 'staging', stage: 'deploy', environment: 'staging', status_event: :success, options: { environment: { on_stop: 'stop staging' } } },
    { name: 'stop staging', stage: 'deploy', environment: 'staging', when: 'manual', status: :skipped },
    { name: 'production', stage: 'deploy', environment: 'production', when: 'manual', status: :skipped },
    { name: 'slack', stage: 'notify', when: 'manual', status: :created },
  ]

  def initialize(project)
    @project = project
  end

  def seed!
    pipelines.each do |pipeline|
      begin
        BUILDS.each { |opts| build_create!(pipeline, opts) }
        commit_status_create!(pipeline, name: 'jenkins', stage: 'test', status: :success)
        print '.'
      rescue ActiveRecord::RecordInvalid
        print 'F'
      ensure
        pipeline.update_status
      end
    end
  end

  private

  def pipelines
    create_master_pipelines + create_merge_request_pipelines
  end

  def create_master_pipelines
    @project.repository.commits('master', limit: 4).map do |commit|
      create_pipeline!(@project, 'master', commit)
    end
  rescue
    []
  end

  def create_merge_request_pipelines
    pipelines = @project.merge_requests.first(3).map do |merge_request|
      project = merge_request.source_project
      branch = merge_request.source_branch

      merge_request.commits.last(4).map do |commit|
        create_pipeline!(project, branch, commit)
      end
    end

    pipelines.flatten
  rescue
    []
  end


  def create_pipeline!(project, ref, commit)
    project.pipelines.create(sha: commit.id, ref: ref)
  end

  def build_create!(pipeline, opts = {})
    attributes = job_attributes(pipeline, opts)
      .merge(commands: '$ build command')

    Ci::Build.create!(attributes).tap do |build|
      # We need to set build trace and artifacts after saving a build
      # (id required), that is why we need `#tap` method instead of passing
      # block directly to `Ci::Build#create!`.

      setup_artifacts(build)
      setup_build_log(build)
      build.save
    end
  end

  def setup_artifacts(build)
    return unless %w[build test].include?(build.stage)

    artifacts_cache_file(artifacts_archive_path) do |file|
      build.artifacts_file = file
    end

    artifacts_cache_file(artifacts_metadata_path) do |file|
      build.artifacts_metadata = file
    end
  end

  def setup_build_log(build)
    if %w(running success failed).include?(build.status)
      build.trace = FFaker::Lorem.paragraphs(6).join("\n\n")
    end
  end

  def commit_status_create!(pipeline, opts = {})
    attributes = job_attributes(pipeline, opts)

    GenericCommitStatus.create!(attributes)
  end

  def job_attributes(pipeline, opts)
    { name: 'test build', stage: 'test', stage_idx: stage_index(opts[:stage]),
      ref: 'master', tag: false, user: build_user, project: @project, pipeline: pipeline,
      created_at: Time.now, updated_at: Time.now
    }.merge(opts)
  end

  def build_user
    @project.team.users.sample
  end

  def build_status
    Ci::Build::AVAILABLE_STATUSES.sample
  end

  def stage_index(stage)
    STAGES.index(stage) || 0
  end

  def artifacts_archive_path
    Rails.root + 'spec/fixtures/ci_build_artifacts.zip'
  end

  def artifacts_metadata_path
    Rails.root + 'spec/fixtures/ci_build_artifacts_metadata.gz'
  end

  def artifacts_cache_file(file_path)
    cache_path = file_path.to_s.gsub('ci_', "p#{@project.id}_")

    FileUtils.copy(file_path, cache_path)
    File.open(cache_path) do |file|
      yield file
    end
  end
end

Gitlab::Seeder.quiet do
  Project.all.sample(5).each do |project|
    project_builds = Gitlab::Seeder::Pipelines.new(project)
    project_builds.seed!
  end
end
