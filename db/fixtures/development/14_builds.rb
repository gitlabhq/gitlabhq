Gitlab::Seeder.quiet do
  project = Project.first
  commits = project.repository.commits('master', nil, 10)
  commits_sha = commits.map { |commit| commit.raw.id }
  ci_commits = commits_sha.map do |sha|
    project.ensure_ci_commit(sha)
  end

  ci_commits.each do |ci_commit|
    ci_commit.create_builds('master', nil, User.first)
  end
end
