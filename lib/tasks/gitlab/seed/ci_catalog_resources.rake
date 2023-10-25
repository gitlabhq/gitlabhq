# frozen_string_literal: true

# Seed CI/CD catalog resources
#
# @param group_path - Group name under which to create the projects
# @param seed_count - Total number of Catalog resources to create (default: 30)
#
# @example
#   bundle exec rake "gitlab:seed:ci_catalog_resources[root, 50]"
#
namespace :gitlab do
  namespace :seed do
    desc 'Seed CI Catalog resources'
    task :ci_catalog_resources,
      [:group_path, :seed_count] => :gitlab_environment do |_t, args|
      Gitlab::Seeders::Ci::Catalog::ResourceSeeder.new(
        group_path: args.group_path,
        seed_count: args.seed_count&.to_i
      ).seed
      puts "Task finished!"
    end
  end
end
