Gitlab::Seeder.quiet do
  Project.all.sample(5).each do |project|
    commits = project.repository.commits('master', nil, 10)
    commits_sha = commits.map { |commit| commit.raw.id }
    ci_commits = commits_sha.map do |sha|
      project.ensure_ci_commit(sha)
    end

    ci_commits.each do |ci_commit|
      attributes = { type: 'Ci::Build', name: 'test build',
                     commands: "$ build command", stage: 'test',
                     stage_idx: 1, ref: 'master', user_id: User.first,
                     gl_project_id: project.id, options: '---- opts',
                     status: %w(running pending success failed canceled).sample,
                     commit_id: ci_commit.id }

      begin
        Ci::Build.create!(attributes)
        print '.'
      rescue ActiveRecord::RecordInvalid
        print 'F'
      end
    end
  end
end
