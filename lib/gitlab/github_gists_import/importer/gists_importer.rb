# frozen_string_literal: true

module Gitlab
  module GithubGistsImport
    module Importer
      class GistsImporter
        attr_reader :user, :client, :already_imported_cache_key

        ALREADY_IMPORTED_CACHE_KEY = 'github-gists-importer/already-imported/%{user}'
        RESULT_CONTEXT = Struct.new(:success?, :error, :waiter, :next_attempt_in, keyword_init: true)

        def initialize(user, token)
          @user = user
          @client = Gitlab::GithubImport::Client.new(token, parallel: true)
          @already_imported_cache_key = format(ALREADY_IMPORTED_CACHE_KEY, user: user.id)
        end

        def execute
          waiter = spread_parallel_import

          expire_already_imported_cache!

          RESULT_CONTEXT.new(success?: true, waiter: waiter)
        rescue Gitlab::GithubImport::RateLimitError => e
          RESULT_CONTEXT.new(success?: false, error: e, next_attempt_in: client.rate_limit_resets_in)
        rescue StandardError => e
          RESULT_CONTEXT.new(success?: false, error: e)
        end

        private

        def spread_parallel_import
          waiter = JobWaiter.new
          worker_arguments = fetch_gists_to_import.map { |gist_hash| [user.id, gist_hash, waiter.key] }
          waiter.jobs_remaining = worker_arguments.size

          schedule_bulk_perform(worker_arguments)
          waiter
        end

        def fetch_gists_to_import
          page_counter = Gitlab::Import::PageCounter.new(user, :gists, 'github-gists-importer')
          collection = []

          client.each_page(:gists, nil, page: page_counter.current) do |page|
            next unless page_counter.set(page.number)

            collection += gists_from(page)
          end

          page_counter.expire!

          collection
        end

        def gists_from(page)
          page.objects.each.with_object([]) do |gist, page_collection|
            gist = gist.to_h
            next if already_imported?(gist)

            page_collection << ::Gitlab::GithubGistsImport::Representation::Gist.from_api_response(gist).to_hash

            mark_as_imported(gist)
          end
        end

        def schedule_bulk_perform(worker_arguments)
          # rubocop:disable Scalability/BulkPerformWithContext
          Gitlab::ApplicationContext.with_context(user: user) do
            Gitlab::GithubGistsImport::ImportGistWorker.bulk_perform_in(
              1.second,
              worker_arguments,
              batch_size: 1000,
              batch_delay: 1.minute
            )
          end
          # rubocop:enable Scalability/BulkPerformWithContext
        end

        def already_imported?(gist)
          Gitlab::Cache::Import::Caching.set_includes?(already_imported_cache_key, gist[:id])
        end

        def mark_as_imported(gist)
          Gitlab::Cache::Import::Caching.set_add(already_imported_cache_key, gist[:id])
        end

        def expire_already_imported_cache!
          Gitlab::Cache::Import::Caching
            .expire(already_imported_cache_key, Gitlab::Cache::Import::Caching::SHORTER_TIMEOUT)
        end
      end
    end
  end
end
