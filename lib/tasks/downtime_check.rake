desc 'Checks if migrations in a branch require downtime'
task downtime_check: :environment do
  # First we'll want to make sure we're comparing with the right upstream
  # repository/branch.
  current_branch = `git rev-parse --abbrev-ref HEAD`.strip

  # Either the developer ran this task directly on the master branch, or they're
  # making changes directly on the master branch.
  if current_branch == 'master'
    if defined?(Gitlab::License)
      repo = 'gitlab-ee'
    else
      repo = 'gitlab-ce'
    end

    `git fetch https://gitlab.com/gitlab-org/#{repo}.git --depth 1`

    compare_with = 'FETCH_HEAD'
  # The developer is working on a different branch, in this case we can just
  # compare with the master branch.
  else
    compare_with = 'master'
  end

  Rake::Task['gitlab:db:downtime_check'].invoke(compare_with)
end
