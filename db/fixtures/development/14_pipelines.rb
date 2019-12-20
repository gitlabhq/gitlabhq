require './spec/support/sidekiq_middleware'

class Gitlab::Seeder::Pipelines
  STAGES = %w[build test deploy notify]
  BUILDS = [
    # build stage
    { name: 'build:linux', stage: 'build', status: :success,
      queued_at: 10.hour.ago, started_at: 9.hour.ago, finished_at: 8.hour.ago },
    { name: 'build:osx', stage: 'build', status: :success,
      queued_at: 10.hour.ago, started_at: 10.hour.ago, finished_at: 9.hour.ago },

    # test stage
    { name: 'rspec:linux 0 3', stage: 'test', status: :success,
      queued_at: 8.hour.ago, started_at: 8.hour.ago, finished_at: 7.hour.ago },
    { name: 'rspec:linux 1 3', stage: 'test', status: :success,
      queued_at: 8.hour.ago, started_at: 8.hour.ago, finished_at: 7.hour.ago },
    { name: 'rspec:linux 2 3', stage: 'test', status: :success,
      queued_at: 8.hour.ago, started_at: 8.hour.ago, finished_at: 7.hour.ago },
    { name: 'rspec:windows 0 3', stage: 'test', status: :success,
      queued_at: 8.hour.ago, started_at: 8.hour.ago, finished_at: 7.hour.ago },
    { name: 'rspec:windows 1 3', stage: 'test', status: :success,
      queued_at: 8.hour.ago, started_at: 8.hour.ago, finished_at: 7.hour.ago },
    { name: 'rspec:windows 2 3', stage: 'test', status: :success,
      queued_at: 8.hour.ago, started_at: 8.hour.ago, finished_at: 7.hour.ago },
    { name: 'rspec:windows 2 3', stage: 'test', status: :success,
      queued_at: 8.hour.ago, started_at: 8.hour.ago, finished_at: 7.hour.ago },
    { name: 'rspec:osx', stage: 'test', status_event: :success,
      queued_at: 8.hour.ago, started_at: 8.hour.ago, finished_at: 7.hour.ago },
    { name: 'spinach:linux', stage: 'test', status: :success,
      queued_at: 8.hour.ago, started_at: 8.hour.ago, finished_at: 7.hour.ago },
    { name: 'spinach:osx', stage: 'test', status: :failed, allow_failure: true,
      queued_at: 8.hour.ago, started_at: 8.hour.ago, finished_at: 7.hour.ago },

    # deploy stage
    { name: 'staging', stage: 'deploy', environment: 'staging', status_event: :success,
      options: { environment: { action: 'start', on_stop: 'stop staging' } },
      queued_at: 7.hour.ago, started_at: 6.hour.ago, finished_at: 4.hour.ago },
    { name: 'stop staging', stage: 'deploy', environment: 'staging',
      when: 'manual', status: :skipped },
    { name: 'production', stage: 'deploy', environment: 'production',
      when: 'manual', status: :skipped },

    # notify stage
    { name: 'slack', stage: 'notify', when: 'manual', status: :success },
  ]
  EXTERNAL_JOBS = [
    { name: 'jenkins', stage: 'test', status: :success,
      queued_at: 7.hour.ago, started_at: 6.hour.ago, finished_at: 4.hour.ago },
  ]

  def initialize(project)
    @project = project
  end

  def seed!
    pipelines.each do |pipeline|
      BUILDS.each { |opts| build_create!(pipeline, opts) }
      EXTERNAL_JOBS.each { |opts| commit_status_create!(pipeline, opts) }
      pipeline.update_duration
      pipeline.update_status
    end
  end

  private

  def pipelines
    create_master_pipelines + create_merge_request_pipelines
  end

  def create_master_pipelines
    @project.repository.commits('master', limit: 4).map do |commit|
      create_pipeline!(@project, 'master', commit).tap do |pipeline|
        random_pipeline.tap do |triggered_by_pipeline|
          triggered_by_pipeline.try(:sourced_pipelines)&.create(
            source_job: triggered_by_pipeline.builds.all.sample,
            source_project: triggered_by_pipeline.project,
            project: pipeline.project,
            pipeline: pipeline)
        end
      end
    end
  rescue ActiveRecord::ActiveRecordError
    []
  end

  def create_merge_request_pipelines
    pipelines = @project.merge_requests.first(3).map do |merge_request|
      project = merge_request.source_project
      branch = merge_request.source_branch

      merge_request.commits.last(4).map do |commit|
        create_pipeline!(project, branch, commit).tap do |pipeline|
          merge_request.update!(head_pipeline_id: pipeline.id)
        end
      end
    end

    pipelines.flatten
  rescue ActiveRecord::ActiveRecordError
    []
  end

  def create_pipeline!(project, ref, commit)
    project.ci_pipelines.create!(sha: commit.id, ref: ref, source: :push)
  end

  def build_create!(pipeline, opts = {})
    attributes = job_attributes(pipeline, opts)

    attributes[:options] ||= {}
    attributes[:options][:script] = 'build command'

    Ci::Build.create!(attributes).tap do |build|
      # We need to set build trace and artifacts after saving a build
      # (id required), that is why we need `#tap` method instead of passing
      # block directly to `Ci::Build#create!`.

      setup_artifacts(build)
      setup_test_reports(build)
      setup_build_log(build)

      build.project.environments.
        find_or_create_by(name: build.expanded_environment_name)

      build.save!
    end
  end

  def setup_artifacts(build)
    return unless build.stage == "build"

    artifacts_cache_file(artifacts_archive_path) do |file|
      build.job_artifacts.build(project: build.project, file_type: :archive, file_format: :zip, file: file)
    end

    artifacts_cache_file(artifacts_metadata_path) do |file|
      build.job_artifacts.build(project: build.project, file_type: :metadata, file_format: :gzip, file: file)
    end
  end

  def setup_test_reports(build)
    return unless build.stage == "test" && build.name == "rspec:osx"

    if build.ref == build.project.default_branch
      artifacts_cache_file(test_reports_pass_path) do |file|
        build.job_artifacts.build(project: build.project, file_type: :junit, file_format: :gzip, file: file)
      end
    else
      artifacts_cache_file(test_reports_failed_path) do |file|
        build.job_artifacts.build(project: build.project, file_type: :junit, file_format: :gzip, file: file)
      end
    end
  end

  def setup_build_log(build)
    if %w(running success failed).include?(build.status)
      build.trace.set(FFaker::Lorem.paragraphs(6).join("\n\n"))
    end
  end

  def commit_status_create!(pipeline, opts = {})
    attributes = job_attributes(pipeline, opts)

    GenericCommitStatus.create!(attributes)
  end

  def job_attributes(pipeline, opts)
    { name: 'test build', stage: 'test', stage_idx: stage_index(opts[:stage]),
      ref: pipeline.ref, tag: false, user: build_user, project: @project, pipeline: pipeline,
      created_at: Time.now, updated_at: Time.now
    }.merge(opts)
  end

  def build_user
    @project.team.users.sample
  end

  def random_pipeline
    Ci::Pipeline.limit(4).all.sample
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

  def test_reports_pass_path
    Rails.root + 'spec/fixtures/junit/junit_ant.xml.gz'
  end

  def test_reports_failed_path
    Rails.root + 'spec/fixtures/junit/junit.xml.gz'
  end

  def artifacts_cache_file(file_path)
    file = Tempfile.new("artifacts")
    file.close

    FileUtils.copy(file_path, file.path)

    yield(UploadedFile.new(file.path, filename: File.basename(file_path)))
  end
end

Gitlab::Seeder.quiet do
  Project.not_mass_generated.sample(5).each do |project|
    project_builds = Gitlab::Seeder::Pipelines.new(project)
    project_builds.seed!
  end
end
