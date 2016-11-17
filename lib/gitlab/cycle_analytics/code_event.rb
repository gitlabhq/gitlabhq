module Gitlab
  module CycleAnalytics
    class CodeEvent < BaseEvent
      def initialize(*args)
        @stage = :code
        @start_time_attrs = issue_metrics_table[:first_mentioned_in_commit_at]
        @end_time_attrs = mr_table[:created_at]
        @projections = [mr_table[:title],
                        mr_table[:iid],
                        mr_table[:id],
                        mr_table[:created_at],
                        mr_table[:state],
                        mr_table[:author_id]]
        @order = mr_table[:created_at]

        super(*args)
      end

      private

      def serialize(event)
        event['author'] = User.find(event.delete('author_id'))

        AnalyticsMergeRequestSerializer.new(project: @project).represent(event).as_json
      end

      def has_permission?(id)
        @options[:current_user].can?(:read_merge_request, MergeRequest.find(id))
      end
    end
  end
end
