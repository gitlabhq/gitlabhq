require 'logger'
require 'resolv-replace'

desc "GitLab | Migrate trace files to trace artifacts"
namespace :gitlab do
  namespace :traces do
    task :migrate, [:relative_path] => :environment do |t, args|
      logger = Logger.new(STDOUT)
      logger.info('Starting migration for trace files')

      logger.info("args.relative_path: #{args.relative_path}")

      Gitlab::Ci::Trace::Migrater.new(args.relative_path).perform
    end
  end
end
