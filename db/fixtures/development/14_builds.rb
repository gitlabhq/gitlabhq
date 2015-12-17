Gitlab::Seeder.quiet do
  build_artifacts_path = Rails.root + 'spec/fixtures/ci_build_artifacts.tar.gz'
  build_artifacts_cache_file = build_artifacts_path.to_s.gsub('ci_', '')

  Project.all.sample(5).each do |project|
    commits = project.repository.commits('master', nil, 5)
    commits_sha = commits.map { |commit| commit.raw.id }
    ci_commits = commits_sha.map do |sha|
      project.ensure_ci_commit(sha)
    end

    ci_commits.each do |ci_commit|
      attributes = { type: 'Ci::Build', name: 'test build', commands: "$ build command",
                     stage: 'test', stage_idx: 1, ref: 'master',
                     user_id: project.team.users.sample, gl_project_id: project.id,
                     status: %w(running pending success failed canceled).sample,
                     commit_id: ci_commit.id, created_at: Time.now, updated_at: Time.now }

      build = Ci::Build.new(attributes)
      build.artifacts_metadata = `tar tzf #{build_artifacts_path}`.split(/\n/)

      FileUtils.copy(build_artifacts_path, build_artifacts_cache_file)
      build.artifacts_file = artifacts_file = File.open(build_artifacts_cache_file, 'r')

      begin
        build.save!
        print '.'
      rescue ActiveRecord::RecordInvalid
        puts build.error.messages.inspect
        print 'F'
      ensure
        artifacts_file.close
      end
    end
  end
end
