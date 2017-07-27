module Gitlab
  module CycleAnalytics
    class PlanEventFetcher < BaseEventFetcher
      def initialize(*args)
        @projections = [mr_diff_table[:id],
                        mr_diff_table[:st_commits],
                        issue_metrics_table[:first_mentioned_in_commit_at]]

        super(*args)
      end

      def events_query
        base_query
          .join(mr_diff_table)
          .on(mr_diff_table[:merge_request_id].eq(mr_table[:id]))

        super
      end

      private

      def merge_request_diff_commits
        @merge_request_diff_commits ||=
          MergeRequestDiffCommit
            .where(merge_request_diff_id: event_result.map { |event| event['id'] })
            .group_by(&:merge_request_diff_id)
      end

      def serialize(event)
        commit = first_time_reference_commit(event)

        return unless commit

        serialize_commit(event, commit, query)
      end

      def first_time_reference_commit(event)
        return nil unless event && merge_request_diff_commits

        commits =
          if event['st_commits'].present?
            YAML.load(event['st_commits'])
          else
            merge_request_diff_commits[event['id'].to_i]
          end

        return nil if commits.blank?

        commits.find do |commit|
          next unless commit[:committed_date] && event['first_mentioned_in_commit_at']

          commit[:committed_date].to_i == DateTime.parse(event['first_mentioned_in_commit_at'].to_s).to_i
        end
      end

      def serialize_commit(event, commit, query)
        commit = Commit.new(Gitlab::Git::Commit.new(commit.to_hash), @project)

        AnalyticsCommitSerializer.new(project: @project, total_time: event['total_time']).represent(commit)
      end
    end
  end
end
