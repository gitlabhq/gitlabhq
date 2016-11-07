module Gitlab
  module CycleAnalytics
    class QueryConfig
      include MetricsFetcher

      def self.get(*args)
        new(*args).get
      end

      def initialize(stage)
        @stage = stage
      end

      def get
        public_send(@stage).freeze if self.respond_to?(@stage)
      end

      def issue
        {
          start_time_attrs: issue_table[:created_at],
          end_time_attrs: [issue_metrics_table[:first_associated_with_milestone_at],
                           issue_metrics_table[:first_added_to_board_at]],
          projections: [issue_table[:title],
                        issue_table[:iid],
                        issue_table[:id],
                        issue_table[:created_at],
                        user_table[:name].as('author_name'),
                        user_table[:username].as('author_username'),
                        user_table[:id].as('author_id')]
        }
      end

      def plan
        {
          start_time_attrs: issue_metrics_table[:first_associated_with_milestone_at],
          end_time_attrs: [issue_metrics_table[:first_added_to_board_at],
                           issue_metrics_table[:first_mentioned_in_commit_at]],
          projections: [mr_diff_table[:st_commits].as('commits')]
        }
      end

      def code
        {
          start_time_attrs: issue_metrics_table[:first_mentioned_in_commit_at],
          end_time_attrs: mr_table[:created_at],
          projections: [mr_table[:title],
                        mr_table[:iid],
                        mr_table[:id],
                        mr_table[:created_at],
                        mr_table[:state],
                        user_table[:name].as('author_name'),
                        user_table[:username].as('author_username'),
                        user_table[:id].as('author_id')],
          order: mr_table[:created_at]
        }
      end

      def test
        {
          start_time_attrs: mr_metrics_table[:latest_build_started_at],
          end_time_attrs: mr_metrics_table[:latest_build_finished_at],
          projections: [build_table[:id]],
          order: build_table[:created_at]
        }
      end

      def review
        {
          start_time_attrs: mr_table[:created_at],
          end_time_attrs: mr_metrics_table[:merged_at],
          projections: [mr_table[:title],
                        mr_table[:iid],
                        mr_table[:id],
                        mr_table[:created_at].as('opened_at'),
                        mr_table[:state],
                        user_table[:name].as('author_name'),
                        user_table[:username].as('author_username'),
                        user_table[:id].as('author_id')]
        }
      end

      def staging
        {
          start_time_attrs: mr_metrics_table[:merged_at],
          end_time_attrs: mr_metrics_table[:first_deployed_to_production_at],
          projections: [build_table[:id]],
          order: build_table[:created_at]
        }
      end

      def production
        {
          start_time_attrs: issue_table[:created_at],
          end_time_attrs: mr_metrics_table[:first_deployed_to_production_at],
          projections: [issue_table[:title],
                        issue_table[:iid],
                        issue_table[:id],
                        issue_table[:created_at],
                        user_table[:name].as('author_name'),
                        user_table[:username].as('author_username'),
                        user_table[:id].as('author_id')]
        }
      end
    end
  end
end
