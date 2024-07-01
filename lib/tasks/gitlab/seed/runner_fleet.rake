# frozen_string_literal: true

# Seed database with:
#   1. 1 organization
#   1. 2 root groups, one with 2 sub-groups and another with 1 sub-group
#   1. 1 project in each of the sub-groups
#   1. 1 instance runner, 1 shared project runner, and group/project runners in some groups/projects
#   1. Successful and failed pipelines assigned to the first 5 available runners of each group/project
#   1. 1 pipeline on one group runner with the remaining jobs
#
# @param username - user creating subgroups (i.e. GitLab admin)
# @param registration_prefix - prefix used for the group, project, and runner names
# @param runner_count - total number of runners to create (default: 40)
# @param job_count - total number of jobs to create and assign to runners (default: 400)
#
# @example
#   bundle exec rake "gitlab:seed:runner_fleet[root, rf-]"
#
namespace :gitlab do
  namespace :seed do
    desc 'Seed groups with sub-groups/projects/runners/jobs for Runner Fleet testing'
    task :runner_fleet,
      [:username, :registration_prefix, :runner_count, :job_count] => :gitlab_environment do |_t, args|
      timings = Benchmark.measure do
        projects_to_runners = Gitlab::Seeders::Ci::Runner::RunnerFleetSeeder.new(
          Gitlab::AppLogger,
          username: args.username,
          registration_prefix: args.registration_prefix,
          runner_count: args.runner_count&.to_i
        ).seed

        if projects_to_runners
          Gitlab::Seeders::Ci::Runner::RunnerFleetPipelineSeeder.new(
            projects_to_runners: projects_to_runners,
            job_count: args.job_count&.to_i
          ).seed
        end
      end

      puts "Seed finished. Timings: #{timings}"
    end
  end
end
