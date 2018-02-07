require 'logger'
require 'resolv-replace'

desc "GitLab | Migrate trace files to trace artifacts"
namespace :gitlab do
  namespace :traces do
    task :migrate, [:relative_path] => :environment do |t, args|
      logger = Logger.new(STDOUT)
      logger.info('Starting migration for trace files')

      trace_path = File.join(Settings.gitlab_ci.builds_path, args.relative_path)

      logger.info("trace_path: #{trace_path}")

      Gitlab::Ci::Trace::Migrater.new(trace_path).perform
    end
  end
end
