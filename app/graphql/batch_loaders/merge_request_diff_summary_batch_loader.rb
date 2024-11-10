# frozen_string_literal: true

module BatchLoaders
  class MergeRequestDiffSummaryBatchLoader
    NIL_STATS = { additions: 0, deletions: 0, file_count: 0 }.freeze

    def self.load_for(merge_request)
      BatchLoader::GraphQL.for(merge_request).batch(key: :diff_stats_summary) do |merge_requests, loader, args|
        Preloaders::MergeRequestDiffPreloader.new(merge_requests).preload_all

        merge_requests.each do |merge_request|
          metrics = merge_request.metrics

          summary = if metrics && metrics.added_lines && metrics.removed_lines
                      {
                        additions: metrics.added_lines,
                        deletions: metrics.removed_lines,
                        file_count: merge_request.merge_request_diff&.files_count || 0
                      }
                    elsif merge_request.diff_stats.blank?
                      NIL_STATS
                    else
                      merge_request.diff_stats.each_with_object(NIL_STATS.dup) do |status, summary|
                        summary.merge!(
                          additions: status.additions,
                          deletions: status.deletions,
                          file_count: 1
                        ) do |_, x, y|
                          x + y
                        end
                      end
                    end

          loader.call(merge_request, summary)
        end
      end
    end
  end
end
