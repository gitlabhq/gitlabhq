# frozen_string_literal: true

namespace :gitlab do
  namespace :snippets do
    DEFAULT_LIMIT = 100

    # @example
    #   bundle exec rake gitlab:snippets:migrate SNIPPET_IDS=1,2,3,4
    #   bundle exec rake gitlab:snippets:migrate SNIPPET_IDS=1,2,3,4 LIMIT=50
    desc 'GitLab | Migrate specific snippets to git'
    task :migrate, [:ids] => :environment do |_, args|
      unless ENV['SNIPPET_IDS'].presence
        raise "Please supply the list of ids through the SNIPPET_IDS env var"
      end

      raise "Invalid limit value" if snippet_task_limit == 0

      if migration_running?
        raise "There are already snippet migrations running. Please wait until they are finished."
      end

      ids = parse_snippet_ids!

      puts "Starting the migration..."
      Gitlab::BackgroundMigration::BackfillSnippetRepositories.new.perform_by_ids(ids)

      list_non_migrated = non_migrated_snippets.where(id: ids)

      if list_non_migrated.exists?
        puts "The following snippets couldn't be migrated:"
        puts list_non_migrated.pluck(:id).join(',')
      else
        puts "All snippets were migrated successfully"
      end
    end

    def parse_snippet_ids!
      ids = ENV['SNIPPET_IDS'].delete(' ').split(',').map do |id|
        id.to_i.tap do |value|
          raise "Invalid id provided" if value == 0
        end
      end

      if ids.size > snippet_task_limit
        raise "The number of ids provided is higher than #{snippet_task_limit}. You can update this limit by using the env var `LIMIT`"
      end

      ids
    end

    # @example
    #   bundle exec rake gitlab:snippets:migration_status
    desc 'GitLab | Show whether there are snippet background migrations running'
    task migration_status: :environment do
      if migration_running?
        puts "There are snippet migrations running"
      else
        puts "There are no snippet migrations running"
      end
    end

    def migration_running?
      store = Gitlab::SidekiqConfig::WorkerRouter.global.store(BackgroundMigrationWorker)
      _, pool = Gitlab::SidekiqSharding::Router.get_shard_instance(store)
      # rubocop:disable Cop/SidekiqApiUsage -- Acceptable to use via to set Sidekiq's redis pool
      Sidekiq::Client.via(pool) do
        Sidekiq::ScheduledSet.new.any? { |r| r.klass == 'BackgroundMigrationWorker' && r.args[0] == 'BackfillSnippetRepositories' }
      end
      # rubocop:enable Cop/SidekiqApiUsage
    end

    # @example
    #   bundle exec rake gitlab:snippets:list_non_migrated
    #   bundle exec rake gitlab:snippets:list_non_migrated LIMIT=50
    desc 'GitLab | Show non migrated snippets'
    task list_non_migrated: :environment do
      raise "Invalid limit value" if snippet_task_limit == 0

      non_migrated_count = non_migrated_snippets.count
      if non_migrated_count == 0
        puts "All snippets have been successfully migrated"
      else
        puts "There are #{non_migrated_count} snippets that haven't been migrated. Showing a batch of ids of those snippets:\n"
        puts non_migrated_snippets.limit(snippet_task_limit).pluck(:id).join(',')
      end
    end

    def non_migrated_snippets
      @non_migrated_snippets ||= Snippet.select(:id).where.not(id: SnippetRepository.select(:snippet_id))
    end

    # There are problems with the specs if we memoize this value
    def snippet_task_limit
      ENV['LIMIT'] ? ENV['LIMIT'].to_i : DEFAULT_LIMIT
    end
  end
end
