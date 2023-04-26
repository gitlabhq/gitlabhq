# frozen_string_literal: true

# Seed instance with CI variables
#
# @param seed_count - total number of CI variables to create (default: 10)
# @param prefix - prefix of the variable key (default: 'INSTANCE_VAR_')
#
# @example
#   bundle exec rake "gitlab:seed:ci_variables_instance[5, INSTANCE_TEST_]"
#
namespace :gitlab do
  namespace :seed do
    desc 'Seed instance with CI Variables'
    task :ci_variables_instance,
      [:seed_count, :prefix] => :gitlab_environment do |_t, args|
      Gitlab::Seeders::Ci::VariablesInstanceSeeder.new(
        seed_count: args.seed_count&.to_i,
        prefix: args&.prefix
      ).seed
      puts "Task finished!"
    end
  end
end
