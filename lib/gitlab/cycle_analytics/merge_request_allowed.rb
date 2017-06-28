module Gitlab
  module CycleAnalytics
    module MergeRequestAllowed
      def allowed_ids
        @allowed_ids ||= MergeRequestsFinder.new(@options[:current_user], project_id: @project.id).execute.where(id: event_result_ids).pluck(:id)
      end
    end
  end
end
