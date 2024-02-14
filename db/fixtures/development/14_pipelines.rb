# frozen_string_literal: true

require './spec/support/sidekiq_middleware'

# Usage:
#
# Simple invocation seeds 5 random projects:
#
# FILTER=14_pipelines bundle exec rake db:seed_fu
#
# Create a new project with repository within a group
#
# FILTER=14_pipelines NEW_PROJECT=1 bundle exec rake db:seed_fu

# rubocop:disable Rails/Output
class Gitlab::Seeder::Pipelines # rubocop:disable Style/ClassAndModuleChildren
  PIPELINE_STAGES = [
    {
      name: 'build',
      position: 0,
      builds: [
        { name: 'build:linux', status: :success,
          queued_at: 10.hours.ago, started_at: 9.hours.ago, finished_at: 8.hours.ago },
        { name: 'build:osx', status: :success,
          queued_at: 10.hours.ago, started_at: 10.hours.ago, finished_at: 9.hours.ago }
      ]
    },
    {
      name: 'test',
      position: 1,
      builds: [
        { name: 'rspec:linux 0 3', status: :success,
          queued_at: 8.hours.ago, started_at: 8.hours.ago, finished_at: 7.hours.ago },
        { name: 'rspec:linux 1 3', status: :success,
          queued_at: 8.hours.ago, started_at: 8.hours.ago, finished_at: 7.hours.ago },
        { name: 'rspec:linux 2 3', status: :success,
          queued_at: 8.hours.ago, started_at: 8.hours.ago, finished_at: 7.hours.ago },
        { name: 'rspec:windows 0 3', status: :success,
          queued_at: 8.hours.ago, started_at: 8.hours.ago, finished_at: 7.hours.ago },
        { name: 'rspec:windows 1 3', status: :success,
          queued_at: 8.hours.ago, started_at: 8.hours.ago, finished_at: 7.hours.ago },
        { name: 'rspec:windows 2 3', status: :success,
          queued_at: 8.hours.ago, started_at: 8.hours.ago, finished_at: 7.hours.ago },
        { name: 'rspec:windows 2 3', status: :success,
          queued_at: 8.hours.ago, started_at: 8.hours.ago, finished_at: 7.hours.ago },
        { name: 'rspec:osx', status_event: :success,
          queued_at: 8.hours.ago, started_at: 8.hours.ago, finished_at: 7.hours.ago },
        { name: 'spinach:linux', status: :success,
          queued_at: 8.hours.ago, started_at: 8.hours.ago, finished_at: 7.hours.ago },
        { name: 'spinach:osx', status: :failed, allow_failure: true,
          queued_at: 8.hours.ago, started_at: 8.hours.ago, finished_at: 7.hours.ago }
      ]
    },
    {
      name: 'deploy',
      position: 2,
      builds: [
        { name: 'staging', environment: 'staging', status_event: :success,
          options: { environment: { action: 'start', on_stop: 'stop staging' } },
          queued_at: 7.hours.ago, started_at: 6.hours.ago, finished_at: 4.hours.ago },
        { name: 'stop staging', environment: 'staging', when: 'manual', status: :skipped },
        { name: 'production', environment: 'production', when: 'manual', status: :skipped }
      ]
    },
    {
      name: 'notify',
      position: 3,
      builds: [
        { name: 'slack', when: 'manual', status: :success }
      ]
    },
    {
      name: 'external',
      position: 4,
      builds: [
        { name: 'jenkins', status: :success,
          queued_at: 7.hours.ago, started_at: 6.hours.ago, finished_at: 4.hours.ago }
      ]
    }
  ].freeze

  def initialize(project = nil)
    @project = project || create_new_project
  end

  def seed!
    if !@project.repository_exists? || @project.empty_repo?
      puts
      puts "==============WARNING=============="
      puts "(#{@project.full_path}) doesn't have a repository. " \
           'Try specifying a project with working repository or add NEW_PROJECT=1 parameter ' \
           'so the seed script will automatically create one.'
      return
    end

    pipelines.each do |pipeline|
      PIPELINE_STAGES.each do |stage_attrs|
        stage = stage_create!(pipeline, stage_attrs[:name], stage_attrs[:position])

        stage_attrs[:builds].each do |build_attrs|
          if stage_attrs[:name] == 'external'
            generic_commit_status_create!(pipeline, stage, build_attrs)
          else
            build_create!(pipeline, stage, build_attrs)
          end
        end
      end

      pipeline.update_duration

      Gitlab::ExclusiveLease.skipping_transaction_check do
        ::Ci::ProcessPipelineService.new(pipeline).execute
      end
    end

    ::Gitlab::Seeders::Ci::DailyBuildGroupReportResult.new(@project).seed if @project.last_pipeline

    puts "\nSuccessfully seeded '#{@project.full_path}'\n"
    puts "URL: #{Rails.application.routes.url_helpers.project_url(@project)}"
  end

  private

  def create_new_project
    admin = User.admins.first

    namespace = FactoryBot.create(
      :group,
      :public,
      name: "Repo Analytics Group #{suffix}",
      path: "r-analytics-group-#{suffix}"
    )
    project = FactoryBot.create(
      :project,
      :public,
      :repository,
      name: "Repo Analytics Project #{suffix}",
      path: "r-analytics-project-#{suffix}",
      creator: admin,
      namespace: namespace
    )

    namespace.add_owner(admin)
    project.create_repository

    project
  end

  def stage_create!(pipeline, name, position)
    Ci::Stage.create!(pipeline: pipeline, project: pipeline.project, name: name, position: position)
  end

  def pipelines
    create_main_pipelines + create_merge_request_pipelines
  end

  def create_main_pipelines
    branch_name = @project.default_branch

    @project.repository.commits(branch_name, limit: 4).map do |commit|
      create_pipeline!(@project, branch_name, commit).tap do |pipeline|
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

  def build_create!(pipeline, stage, opts = {})
    attributes = job_attributes(pipeline, stage, opts)

    attributes[:options] ||= {}
    attributes[:options][:script] = 'build command'

    Ci::Build.create!(attributes).tap do |build|
      # We need to set build trace and artifacts after saving a build
      # (id required), that is why we need `#tap` method instead of passing
      # block directly to `Ci::Build#create!`.

      setup_artifacts(build)
      setup_test_reports(build)
      setup_build_log(build)

      build.project.environments
        .find_or_create_by(name: build.expanded_environment_name)

      build.save!
    end
  end

  def setup_artifacts(build)
    return unless build.ci_stage.name == 'build'

    artifacts_cache_file(artifacts_archive_path) do |file|
      build.job_artifacts.build(project: build.project, file_type: :archive, file_format: :zip, file: file)
    end

    artifacts_cache_file(artifacts_metadata_path) do |file|
      build.job_artifacts.build(project: build.project, file_type: :metadata, file_format: :gzip, file: file)
    end
  end

  def setup_test_reports(build)
    return unless build.ci_stage.name == 'test' && build.name == "rspec:osx"

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
    return unless %w[running success failed].include?(build.status)

    Gitlab::ExclusiveLease.skipping_transaction_check do
      build.trace.set(FFaker::Lorem.paragraphs(6).join("\n\n"))
    end
  end

  def generic_commit_status_create!(pipeline, stage, opts = {})
    attributes = job_attributes(pipeline, stage, opts)

    GenericCommitStatus.create!(attributes)
  end

  def runners
    @runners ||= FactoryBot.create_list(:ci_runner, 6)
  end

  def job_attributes(pipeline, stage, opts)
    {
      name: 'test build', ci_stage: stage, stage_idx: stage.position,
      ref: pipeline.ref, tag: false, user: build_user, project: @project, pipeline: pipeline,
      scheduling_type: :stage, created_at: Time.now, updated_at: Time.now, runner_id: runners.sample.id
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

  def artifacts_archive_path
    "#{Rails.root}/spec/fixtures/ci_build_artifacts.zip"
  end

  def artifacts_metadata_path
    "#{Rails.root}/spec/fixtures/ci_build_artifacts_metadata.gz"
  end

  def test_reports_pass_path
    "#{Rails.root}/spec/fixtures/junit/junit_ant.xml.gz"
  end

  def test_reports_failed_path
    "#{Rails.root}/spec/fixtures/junit/junit.xml.gz"
  end

  def artifacts_cache_file(file_path)
    file = Tempfile.new("artifacts")
    file.close

    FileUtils.copy(file_path, file.path)

    yield(UploadedFile.new(file.path, filename: File.basename(file_path)))
  end

  def suffix
    @suffix ||= Time.now.to_i
  end
end

Gitlab::Seeder.quiet do
  new_project = ENV['NEW_PROJECT']

  if new_project.present?
    Gitlab::Seeder::Pipelines.new.seed!
  else
    Project.not_mass_generated.sample(5).each do |project|
      project_builds = Gitlab::Seeder::Pipelines.new(project)
      project_builds.seed!
    end
  end
end
# rubocop:enable Rails/Output
