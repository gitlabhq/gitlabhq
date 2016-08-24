desc 'Checks if migrations in a branch require downtime'
task downtime_check: :environment do
  if defined?(Gitlab::License)
    repo = 'gitlab-ee'
  else
    repo = 'gitlab-ce'
  end

  `git fetch https://gitlab.com/gitlab-org/#{repo}.git --depth 1`

  Rake::Task['gitlab:db:downtime_check'].invoke('FETCH_HEAD')
end
