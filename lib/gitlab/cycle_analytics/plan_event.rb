module Gitlab
  module CycleAnalytics
    class PlanEvent < BaseEvent
      def initialize(*args)
        @stage = :plan
        @start_time_attrs = issue_metrics_table[:first_associated_with_milestone_at]
        @end_time_attrs = [issue_metrics_table[:first_added_to_board_at],
                           issue_metrics_table[:first_mentioned_in_commit_at]]
        @projections = [mr_diff_table[:st_commits].as('commits'),
                        issue_metrics_table[:first_mentioned_in_commit_at]]

        super(*args)
      end

      def custom_query(base_query)
        base_query.join(mr_diff_table).on(mr_diff_table[:merge_request_id].eq(mr_table[:id]))
      end

      private

      def serialize(event)
        st_commit = first_time_reference_commit(event.delete('commits'), event)

        return unless st_commit

        serialize_commit(event, st_commit, query)
      end

      def first_time_reference_commit(commits, event)
        return nil if commits.blank?

        YAML.load(commits).find do |commit|
          next unless commit[:committed_date] && event['first_mentioned_in_commit_at']

          commit[:committed_date].to_i == DateTime.parse(event['first_mentioned_in_commit_at'].to_s).to_i
        end
      end

      def serialize_commit(event, st_commit, query)
        commit = Commit.new(Gitlab::Git::Commit.new(st_commit), @project)

        AnalyticsCommitSerializer.new(project: @project, total_time: event['total_time']).represent(commit).as_json
      end
    end
  end
end
