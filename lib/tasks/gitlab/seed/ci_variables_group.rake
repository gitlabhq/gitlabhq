# frozen_string_literal: true

# Seed group with CI variables
#
# @param name - name of the group to add CI variables to
# @param seed_count - total number of CI variables to create (default: 10)
# @param environment_scope - environment scope of the variable (default: '*')
#   If "unique", it will create a unique environment_scope per variable.
# @param prefix - prefix of the variable key (default: 'GROUP_VAR_')
#
# @example
#   bundle exec rake "gitlab:seed:ci_variables_group[kitchen-sink, 5, unique]"
#
namespace :gitlab do
  namespace :seed do
    desc 'Seed group with CI Variables'
    task :ci_variables_group,
      [:name, :seed_count, :environment_scope, :prefix] => :gitlab_environment do |_t, args|
      Gitlab::Seeders::Ci::VariablesGroupSeeder.new(
        name: args.name,
        seed_count: args.seed_count&.to_i,
        prefix: args&.prefix,
        environment_scope: args&.environment_scope
      ).seed
      puts "Task finished!"
    end
  end
end
