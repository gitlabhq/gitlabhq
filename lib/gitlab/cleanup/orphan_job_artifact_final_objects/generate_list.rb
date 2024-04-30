# frozen_string_literal: true

module Gitlab
  module Cleanup
    module OrphanJobArtifactFinalObjects
      class GenerateList
        include StorageHelpers

        UnsupportedProviderError = Class.new(StandardError)

        DEFAULT_FILENAME = 'orphan_job_artifact_final_objects.csv'
        LAST_PAGE_MARKER_REDIS_KEY = 'orphan-job-artifact-objects-cleanup-last-page-marker'

        PAGINATORS = {
          google: Gitlab::Cleanup::OrphanJobArtifactFinalObjects::Paginators::Google,
          aws: Gitlab::Cleanup::OrphanJobArtifactFinalObjects::Paginators::Aws,
          azurerm: Gitlab::Cleanup::OrphanJobArtifactFinalObjects::Paginators::Azure
        }.freeze

        def initialize(provider: nil, filename: nil, force_restart: false, logger: Gitlab::AppLogger)
          @paginator = determine_paginator!(provider)
          @force_restart = force_restart
          @logger = logger
          @filename = filename || DEFAULT_FILENAME
        end

        def run!
          log_info('Looking for orphan job artifact objects under the `@final` directories')

          initialize_file

          each_batch do |fog_collection|
            BatchFromStorage.new(fog_collection, bucket_prefix: bucket_prefix).orphan_objects.each do |fog_file|
              log_orphan_object(fog_file)
            end
          end

          log_info("Done. All orphan objects are listed in #{filename}.")
        ensure
          file&.close
        end

        private

        attr_reader :paginator, :file, :filename, :force_restart, :logger

        def initialize_file
          # If the file already exists, and this is not a force restart,
          # new entries will be appended to it. Otherwise, force restart will
          # cause a truncation of the existing file.
          mode = force_restart ? 'w+' : 'a+'
          @file = File.open(filename, mode)
        end

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
            # Set TTL to 1 week (86400 * 7 seconds)
            redis.set(LAST_PAGE_MARKER_REDIS_KEY, marker, ex: 604_800)
          end
        end

        def clear_last_page_marker
          Gitlab::Redis::SharedState.with do |redis|
            redis.del(LAST_PAGE_MARKER_REDIS_KEY)
          end
        end

        def log_orphan_object(fog_file)
          add_orphan_object_to_list(fog_file)
          log_info("Found orphan object #{fog_file.key} (#{fog_file.content_length} bytes)")
        end

        def add_orphan_object_to_list(fog_file)
          file.puts([fog_file.key, fog_file.content_length].join(','))
        end

        def log_info(msg)
          logger.info(msg)
        end
      end
    end
  end
end
