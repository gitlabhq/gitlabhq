class Gitlab::Seeder::Builds
  STAGES = %w[build notify_build test notify_test deploy notify_deploy]

  def initialize(project)
    @project = project
  end

  def seed!
    pipelines.each do |pipeline|
      begin
        build_create!(pipeline, name: 'build:linux', stage: 'build', status_event: :success)
        build_create!(pipeline, name: 'build:osx', stage: 'build', status_event: :success)

        build_create!(pipeline, name: 'slack post build', stage: 'notify_build', status_event: :success)

        build_create!(pipeline, name: 'rspec:linux', stage: 'test', status_event: :success)
        build_create!(pipeline, name: 'rspec:windows', stage: 'test', status_event: :success)
        build_create!(pipeline, name: 'rspec:windows', stage: 'test', status_event: :success)
        build_create!(pipeline, name: 'rspec:osx', stage: 'test', status_event: :success)
        build_create!(pipeline, name: 'spinach:linux', stage: 'test', status: :pending)
        build_create!(pipeline, name: 'spinach:osx', stage: 'test', status_event: :cancel)
        build_create!(pipeline, name: 'cucumber:linux', stage: 'test', status_event: :run)
        build_create!(pipeline, name: 'cucumber:osx', stage: 'test', status_event: :drop)

        build_create!(pipeline, name: 'slack post test', stage: 'notify_test', status_event: :success)

        build_create!(pipeline, name: 'staging', stage: 'deploy', environment: 'staging', status_event: :success)
        build_create!(pipeline, name: 'production', stage: 'deploy', environment: 'production', when: 'manual', status: :success)

        commit_status_create!(pipeline, name: 'jenkins', status: :success)

        print '.'
      rescue ActiveRecord::RecordInvalid
        print 'F'
      end
    end
  end

  def pipelines
    commits = @project.repository.commits('master', limit: 5)
    commits_sha = commits.map { |commit| commit.raw.id }
    commits_sha.map do |sha|
      @project.ensure_pipeline('master', sha)
    end
  rescue
    []
  end

  def build_create!(pipeline, opts = {})
    attributes = build_attributes_for(pipeline, opts)
    build = Ci::Build.create!(attributes)

    if opts[:name].start_with?('build')
      artifacts_cache_file(artifacts_archive_path) do |file|
        build.artifacts_file = file
      end

      artifacts_cache_file(artifacts_metadata_path) do |file|
        build.artifacts_metadata = file
      end
    end

    if %w(running success failed).include?(build.status)
      # We need to set build trace after saving a build (id required)
      build.trace = FFaker::Lorem.paragraphs(6).join("\n\n")
    end
  end

  def commit_status_create!(pipeline, opts = {})
    attributes = commit_status_attributes_for(pipeline, opts)
    GenericCommitStatus.create!(attributes)
  end

  def commit_status_attributes_for(pipeline, opts)
    { name: 'test build', stage: 'test', stage_idx: stage_index(opts[:stage]),
      ref: 'master', tag: false, user: build_user, project: @project, pipeline: pipeline,
      created_at: Time.now, updated_at: Time.now
    }.merge(opts)
  end

  def build_attributes_for(pipeline, opts)
    commit_status_attributes_for(pipeline, opts).merge(commands: '$ build command')
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
  Project.all.sample(10).each do |project|
    project_builds = Gitlab::Seeder::Builds.new(project)
    project_builds.seed!
  end
end
