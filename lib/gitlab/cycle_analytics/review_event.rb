module Gitlab
  module CycleAnalytics
    class ReviewEvent < BaseEvent
      def initialize(*args)
        @stage = :review
        @start_time_attrs = mr_table[:created_at]
        @end_time_attrs = mr_metrics_table[:merged_at]
        @projections = [mr_table[:title],
                        mr_table[:iid],
                        mr_table[:id],
                        mr_table[:created_at],
                        mr_table[:state],
                        mr_table[:author_id]]

        super(*args)
      end

      def serialize(event)
        AnalyticsMergeRequestSerializer.new(project: @project).represent(event).as_json
      end

      def allowed_ids
        @allowed_ids ||= MergeRequestsFinder.new(@options[:current_user], project_id: @project.id).execute.where(id: event_result_ids).pluck(:id)
      end
    end
  end
end
