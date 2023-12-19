# frozen_string_literal: true

# Seed CI/CD catalog resources
#
# @param group_path - Group name under which to create the projects
# @param seed_count - Total number of Catalog resources to create
# @param publish - Whether or not created resources should be published in the catalog. Defaults to true.
#
# @example to create published resources
#   bundle exec rake "gitlab:seed:ci_catalog_resources[Twitter, 50]"
# @example to create draft resources
#   bundle exec rake "gitlab:seed:ci_catalog_resources[Flightjs, 2, false]"
#
namespace :gitlab do
  namespace :seed do
    desc 'Seed CI Catalog resources'
    task :ci_catalog_resources,
      [:group_path, :seed_count, :publish] => :gitlab_environment do |_t, args|
      Gitlab::Seeders::Ci::Catalog::ResourceSeeder.new(
        group_path: args.group_path,
        seed_count: args.seed_count.to_i,
        publish: Gitlab::Utils.to_boolean(args.publish, default: true)
      ).seed
      puts "Task finished!"
    end
  end
end
