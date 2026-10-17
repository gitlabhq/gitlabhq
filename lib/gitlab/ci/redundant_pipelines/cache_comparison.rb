# frozen_string_literal: true

module Gitlab
  module Ci
    module RedundantPipelines
      # Compares what the search decided with what the cache path would decide,
      # so the cache can be checked before cancellation reads from it.
      class CacheComparison
        MAX_LOGGED_IDS = 20
        BATCH_SIZE = 1_000

        def self.for(pipeline)
          new(cache: CandidateCache.for(project_id: pipeline.project_id, ref: pipeline.ref))
        end

        def initialize(cache:)
          @cache = cache
          @canceled = []
          @canceled_conservatively = []
          @kept_as_protected = []
        end

        def canceled(older_pipeline)
          @canceled << older_pipeline
        end

        def canceled_conservatively(older_pipeline)
          canceled(older_pipeline)
          @canceled_conservatively << older_pipeline
        end

        def kept_as_protected(older_pipeline)
          @kept_as_protected << older_pipeline
        end

        def log_fields
          {
            cache_missed_count: missed.size,
            cache_missed_ids: logged_ids(missed),
            cache_would_cancel_count: would_cancel.size,
            cache_would_cancel_ids: logged_ids(would_cancel),
            cache_would_cancel_never_started_count: would_cancel_never_started.size,
            cache_would_cancel_never_started_ids: logged_ids(would_cancel_never_started),
            cache_would_keep_count: would_keep.size,
            cache_would_keep_ids: logged_ids(would_keep)
          }
        end

        private

        attr_reader :cache

        # The cache never holds child pipelines. They are canceled with their parent.
        def missed
          @missed ||= begin
            keys = @canceled.reject(&:parent_pipeline?).index_with { |older| PipelineKey.of(older) }
            registered = cache.registered_among(keys.values).to_set

            keys.reject { |_older, key| registered.include?(key) }.keys
          end
        end

        def would_cancel
          @would_cancel ||= unprotected_kept.select { |older| started_ids.include?(older.id) }
        end

        def would_cancel_never_started
          @would_cancel_never_started ||= unprotected_kept.reject { |older| started_ids.include?(older.id) }
        end

        def unprotected_kept
          @unprotected_kept ||= @kept_as_protected.reject { |older| protected?(older) }
        end

        def would_keep
          @would_keep ||= @canceled_conservatively.select { |older| protected?(older) }
        end

        def protected?(older_pipeline)
          protected_ids.include?(older_pipeline.id)
        end

        # rubocop: disable CodeReuse/ActiveRecord -- Temporary rollout check
        def protected_ids
          @protected_ids ||= begin
            in_redis = cache.protected_among(conservative.map { |older| PipelineKey.of(older) })

            in_column_ids.merge(in_redis.map(&:pipeline_id))
          end
        end

        def conservative
          @conservative ||= @kept_as_protected + @canceled_conservatively
        end

        def in_column_ids
          conservative.each_slice(BATCH_SIZE).flat_map do |batch|
            ::Ci::PipelineProcessingData.where(
              pipeline_id: batch.map(&:id),
              partition_id: batch.map(&:partition_id).uniq,
              interruptible_protected: true
            ).limit(batch.size).pluck(:pipeline_id)
          end.to_set
        end

        def started_ids
          @started_ids ||= begin
            ran = ::Ci::Build.scoped_pipeline
              .with_status(::Ci::Pipeline::STARTED_STATUSES)
              .with_interruptible_false
              .where.not(started_at: nil)

            unprotected_kept.map(&:id).each_slice(BATCH_SIZE).flat_map do |batch|
              ::Ci::Pipeline.primary_key_in(batch).where_exists(ran).pluck_primary_key
            end.to_set
          end
        end
        # rubocop: enable CodeReuse/ActiveRecord

        def logged_ids(pipelines)
          pipelines.first(MAX_LOGGED_IDS).map(&:id)
        end
      end
    end
  end
end
