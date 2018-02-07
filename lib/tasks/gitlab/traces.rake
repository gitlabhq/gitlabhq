require 'logger'
require 'resolv-replace'

desc "GitLab | Migrate trace files to trace artifacts"
namespace :gitlab do
  namespace :traces do
    task :migrate, [:relative_path] => :environment do |t, args|
      logger = Logger.new(STDOUT)
      logger.info('Starting migration for trace files')

      Gitlab::Ci::Trace::FileIterator.new(args.relative_path).trace_files do |trace_path|
        logger.info("Migrating... #{trace_path}")

        Gitlab::Ci::Trace::Migrator.new(trace_path).perform
      end
    end
  end
end
