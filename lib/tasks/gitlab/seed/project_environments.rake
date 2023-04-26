# frozen_string_literal: true

# Seed project with environments
#
# @param project_path - path of the project to add environments to
# @param seed_count - total number of environments to create (default: 10)
# @param prefix - prefix used for the environment name (default: 'ENV_')
#
# @example
#   bundle exec rake "gitlab:seed:project_environments[root/paper, 5, staging_]"
#
namespace :gitlab do
  namespace :seed do
    desc 'Seed project with environments'
    task :project_environments, [:project_path, :seed_count, :prefix] => :gitlab_environment do |_t, args|
      Gitlab::Seeders::ProjectEnvironmentSeeder.new(
        project_path: args.project_path,
        seed_count: args.seed_count&.to_i,
        prefix: args&.prefix
      ).seed
      puts "Task finished!"
    end
  end
end
