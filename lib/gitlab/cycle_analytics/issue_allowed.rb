module Gitlab
  module CycleAnalytics
    module IssueAllowed
      def allowed_ids
        @allowed_ids ||= IssuesFinder.new(@options[:current_user], project_id: @project.id).execute.where(id: event_result_ids).pluck(:id)
      end
    end
  end
end
