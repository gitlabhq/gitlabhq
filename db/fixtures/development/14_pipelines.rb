require './spec/support/sidekiq'

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
    { name: 'java ant', stage: 'test', status: :failed, allow_failure: true,
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

  def create_running_pipeline_with_test_reports(ref, rspec_pattern:, ant_pattern:)
    raise 'Unknown result_pattern' unless %w[pass failed-1 failed-2 failed-3].include?(rspec_pattern)
    raise 'Unknown result_pattern' unless %w[pass failed-1 failed-2 failed-3].include?(ant_pattern)

    last_commit = @project.repository.commit(ref)
    pipeline = create_pipeline!(@project, ref, last_commit)

    @project.merge_requests.find_by_source_branch(ref).update!(head_pipeline_id: pipeline.id) if ref != 'master'

    (0...3).each do |index|
      Ci::Build.create!(name: "rspec:pg #{index} 3", stage: 'test', status: :running, project: @project, pipeline: pipeline, ref: ref).tap do |build|
        path = Rails.root + "spec/fixtures/junit/#{rspec_pattern}-rspec-#{index}-3.xml.gz"

        artifacts_cache_file(path) do |file|
          build.job_artifacts.create!(project: build.project, file_type: :junit, file_format: :gzip, file: file)
        end
      end
    end

    Ci::Build.create!(name: "java ant", stage: 'test', status: :running, project: @project, pipeline: pipeline, ref: ref).tap do |build|
      path = Rails.root + "spec/fixtures/junit/#{ant_pattern}-ant-test.xml.gz"

      artifacts_cache_file(path) do |file|
        build.job_artifacts.create!(project: build.project, file_type: :junit, file_format: :gzip, file: file)
      end
    end

    pipeline.update_duration
    pipeline.update_status
  end

  def finish_last_pipeline(ref)
    last_pipeline = @project.pipelines.where(ref: ref).last
    last_pipeline.builds.update_all(status: :success)
    last_pipeline.update_status
  end

  def destroy_pipeline(ref)
    @project.pipelines.where(ref: ref).destroy_all
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
        create_pipeline!(project, branch, commit).tap do |pipeline|
          merge_request.update!(head_pipeline_id: pipeline.id)
        end
      end
    end

    pipelines.flatten
  rescue
    []
  end


  def create_pipeline!(project, ref, commit)
    project.pipelines.create!(sha: commit.id, ref: ref, source: :push)
  end

  def build_create!(pipeline, opts = {})
    attributes = job_attributes(pipeline, opts)
      .merge(commands: '$ build command')

    Ci::Build.create!(attributes).tap do |build|
      # We need to set build trace and artifacts after saving a build
      # (id required), that is why we need `#tap` method instead of passing
      # block directly to `Ci::Build#create!`.

      setup_artifacts(build) if %w[build test].include?(build.stage)
      setup_test_reports(build) if %w[test].include?(build.stage)
      setup_build_log(build)

      build.project.environments.
        find_or_create_by(name: build.expanded_environment_name)

      build.save!
    end
  end

  def setup_artifacts(build)
    artifacts_cache_file(artifacts_archive_path) do |file|
      build.job_artifacts.build(project: build.project, file_type: :archive, file_format: :zip, file: file)
    end

    artifacts_cache_file(artifacts_metadata_path) do |file|
      build.job_artifacts.build(project: build.project, file_type: :metadata, file_format: :gzip, file: file)
    end
  end

  def setup_test_reports(build)
    if build.ref == build.project.default_branch
      if build.name.include?('rspec:linux')
        artifacts_cache_file(artifacts_rspec_junit_master_path(build.name)) do |file|
          build.job_artifacts.build(project: build.project, file_type: :junit, file_format: :gzip, file: file)
        end
      elsif build.name.include?('java ant')
        artifacts_cache_file(artifacts_ant_junit_master_path) do |file|
          build.job_artifacts.build(project: build.project, file_type: :junit, file_format: :gzip, file: file)
        end
      end
    else
      if build.name.include?('rspec:linux')
        artifacts_rspec_junit_feature_path(build.name).try do |path|
          artifacts_cache_file(path) do |file|
            build.job_artifacts.build(project: build.project, file_type: :junit, file_format: :gzip, file: file)
          end
        end
      elsif build.name.include?('java ant')
        artifacts_cache_file(artifacts_ant_junit_feature_path) do |file|
          build.job_artifacts.build(project: build.project, file_type: :junit, file_format: :gzip, file: file)
        end
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

  def artifacts_rspec_junit_master_path(build_name)
    index, total = build_name.scan(/ (\d) (\d)/).first
    Rails.root + "spec/fixtures/junit/junit_master_rspec_#{index}_#{total}.xml.gz"
  end

  def artifacts_rspec_junit_feature_path(build_name)
    index, total = build_name.scan(/ (\d) (\d)/).first
    Rails.root + "spec/fixtures/junit/junit_feature_rspec_#{index}_#{total}.xml.gz"
  end

  def artifacts_ant_junit_master_path
    Rails.root + "spec/fixtures/junit/junit_master_ant.xml.gz"
  end

  def artifacts_ant_junit_feature_path
    Rails.root + "spec/fixtures/junit/junit_feature_ant.xml.gz"
  end

  def artifacts_cache_file(file_path)
    file = Tempfile.new("artifacts")
    file.close

    FileUtils.copy(file_path, file.path)

    yield(UploadedFile.new(file.path, filename: File.basename(file_path)))
  end
end

# Gitlab::Seeder.quiet do
#   Project.all.sample(5).each do |project|
#     project_builds = Gitlab::Seeder::Pipelines.new(project)
#     project_builds.seed!
#   end
# end
