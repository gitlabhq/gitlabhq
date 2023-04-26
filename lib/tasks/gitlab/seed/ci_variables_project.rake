# frozen_string_literal: true

# Seed project with CI variables
#
# @param project_path - path of the project to add CI variables to
# @param seed_count - total number of CI variables to create (default: 10)
# @param environment_scope - environment scope of the variable (default: '*')
#   If "unique", it will create a unique environment_scope per variable.
# @param prefix - prefix of the variable key (default: 'VAR_')
#
# @example
#   bundle exec rake "gitlab:seed:ci_variables_project[root/paper, 5, production, prod_var_]"
#
namespace :gitlab do
  namespace :seed do
    desc 'Seed project with CI Variables'
    task :ci_variables_project,
      [:project_path, :seed_count, :environment_scope, :prefix] => :gitlab_environment do |_t, args|
      Gitlab::Seeders::Ci::VariablesProjectSeeder.new(
        project_path: args.project_path,
        seed_count: args.seed_count&.to_i,
        prefix: args&.prefix,
        environment_scope: args&.environment_scope
      ).seed
      puts "Task finished!"
    end
  end
end
