# frozen_string_literal: true

module Gitlab
  module Cleanup
    class OrphanJobArtifactFinalObjectsCleaner
      include Gitlab::Utils::StrongMemoize

      UnsupportedProviderError = Class.new(StandardError)

      PAGINATORS = {
        google: Gitlab::Cleanup::OrphanJobArtifactFinalObjects::Paginators::Google,
        aws: Gitlab::Cleanup::OrphanJobArtifactFinalObjects::Paginators::Aws
      }.freeze

      LAST_PAGE_MARKER_REDIS_KEY = 'orphan-job-artifact-objects-cleanup-last-page-marker'

      def initialize(provider: nil, dry_run: true, force_restart: false, logger: Gitlab::AppLogger)
        @paginator = determine_paginator!(provider)
        @dry_run = dry_run
        @force_restart = force_restart
        @logger = logger
      end

      def run!
        log_info('Looking for orphan job artifact objects under the `@final` directories')

        each_final_object do |object|
          next unless object.orphan?

          object.delete unless dry_run
          log_info("Delete #{object.path} (#{object.size} bytes)")
        end

        log_info("Done.")
      end

      private

      attr_reader :paginator, :dry_run, :force_restart, :logger

      def determine_paginator!(provided_provider)
        # provider can be nil if user didn't specify it when running the clean up task.
        # In this case, we automatically determine the provider based on the object storage configuration.
        provider = provided_provider
        provider ||= configuration.connection.provider
        klass = PAGINATORS.fetch(provider.downcase.to_sym)
        klass.new(bucket_prefix: bucket_prefix)
      rescue KeyError
        msg = if provided_provider.present?
                "The provided provider is unsupported. Please select from #{PAGINATORS.keys.join(', ')}."
              else
                <<-MSG.strip_heredoc
                  The provider found in the object storage configuration is unsupported.
                  Please re-run the task and specify a provider from #{PAGINATORS.keys.join(', ')},
                  whichever is compatible with your provider's object storage API."
                MSG
              end

        raise UnsupportedProviderError, msg
      end

      def each_final_object
        each_batch do |files|
          files.each_file_this_page do |fog_file|
            object = ::Gitlab::Cleanup::OrphanJobArtifactFinalObjects::JobArtifactObject.new(
              fog_file,
              bucket_prefix: bucket_prefix
            )

            # We still need to check here if the object is in the final location because
            # if the provider does not support filtering objects by glob pattern, we will
            # then receive all job artifact objects here, even the ones not in the @final directory.
            yield object if object.in_final_location?
          end
        end
      end

      def each_batch
        next_marker = resume_from_last_page_marker

        loop do
          batch = fetch_batch(next_marker)
          yield batch

          break if paginator.last_page?(batch)

          next_marker = paginator.get_next_marker(batch)
          save_last_page_marker(next_marker)
        end

        clear_last_page_marker
      end

      def fetch_batch(marker)
        page_name = marker ? "marker: #{marker}" : "first page"
        log_info("Loading page (#{page_name})")

        # We are using files.all instead of files.each because we want to track the
        # current page token so that we can resume from it if ever the task is abruptly interrupted.
        artifacts_directory.files.all(
          paginator.filters(marker)
        )
      end

      def resume_from_last_page_marker
        if force_restart
          log_info("Force restarted. Will not resume from last known page marker.")
          nil
        else
          get_last_page_marker
        end
      end

      def get_last_page_marker
        Gitlab::Redis::SharedState.with do |redis|
          marker = redis.get(LAST_PAGE_MARKER_REDIS_KEY)
          log_info("Resuming from last page marker: #{marker}") if marker
          marker
        end
      end

      def save_last_page_marker(marker)
        Gitlab::Redis::SharedState.with do |redis|
          # Set TTL to 1 day (86400 seconds)
          redis.set(LAST_PAGE_MARKER_REDIS_KEY, marker, ex: 86400)
        end
      end

      def clear_last_page_marker
        Gitlab::Redis::SharedState.with do |redis|
          redis.del(LAST_PAGE_MARKER_REDIS_KEY)
        end
      end

      def connection
        ::Fog::Storage.new(configuration['connection'].symbolize_keys)
      end

      def configuration
        Gitlab.config.artifacts.object_store
      end

      def bucket
        configuration.remote_directory
      end

      def bucket_prefix
        configuration.bucket_prefix
      end

      def artifacts_directory
        connection.directories.new(key: bucket)
      end
      strong_memoize_attr :artifacts_directory

      def log_info(msg)
        logger.info("#{'[DRY RUN] ' if dry_run}#{msg}")
      end
    end
  end
end
