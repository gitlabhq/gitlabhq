class Gitlab::Seeder::Builds
  def initialize(project)
    @project = project
  end

  def seed!
    ci_commits.each do |ci_commit|
      begin
        build_create!(ci_commit, name: 'test build 1')
        build_create!(ci_commit, status: 'success', name: 'test build 2')
        print '.'
      rescue ActiveRecord::RecordInvalid
        print 'F'
      end
    end
  end

  def ci_commits
    commits = @project.repository.commits('master', nil, 5)
    commits_sha = commits.map { |commit| commit.raw.id }
    commits_sha.map do |sha|
      @project.ensure_ci_commit(sha)
    end
  rescue
    []
  end

  def build_create!(ci_commit, opts = {})
    attributes = build_attributes_for(ci_commit).merge(opts)
    build = Ci::Build.new(attributes)

    if %w(success failed).include?(build.status)
      artifacts_cache_file(artifacts_archive_path) do |file|
        build.artifacts_file = file
      end

      artifacts_cache_file(artifacts_metadata_path) do |file|
        build.artifacts_metadata = file
      end
    end

    build.save!

    if %w(running success failed).include?(build.status)
      # We need to set build trace after saving a build (id required)
      build.trace = FFaker::Lorem.paragraphs(6).join("\n\n")
    end
  end

  def build_attributes_for(ci_commit)
    { name: 'test build', commands: "$ build command",
      stage: 'test', stage_idx: 1, ref: 'master',
      user_id: build_user, gl_project_id: @project.id,
      status: build_status, commit_id: ci_commit.id,
      created_at: Time.now, updated_at: Time.now }
  end

  def build_user
    @project.team.users.sample
  end

  def build_status
    Ci::Build::AVAILABLE_STATUSES.sample
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
