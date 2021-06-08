# frozen_string_literal: true

require 'logger'

desc "GitLab | Packages | Build composer cache"
namespace :gitlab do
  namespace :packages do
    task build_composer_cache: :environment do
      logger = Logger.new($stdout)
      logger.info('Starting to build composer cache files')

      ::Packages::Package.composer.find_in_batches do |packages|
        packages.group_by { |pkg| [pkg.project_id, pkg.name] }.each do |(project_id, name), packages|
          logger.info("Building cache for #{project_id} -> #{name}")
          Gitlab::Composer::Cache.new(project: packages.first.project, name: name).execute
        end
      end
    end
  end
end
