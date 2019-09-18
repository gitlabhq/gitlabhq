desc 'Checks if migrations in a branch require downtime'
task downtime_check: :environment do
  repo = if defined?(Gitlab::License)
           'gitlab'
         else
           'gitlab-foss'
         end

  `git fetch https://gitlab.com/gitlab-org/#{repo}.git --depth 1`

  Rake::Task['gitlab:db:downtime_check'].invoke('FETCH_HEAD')
end
