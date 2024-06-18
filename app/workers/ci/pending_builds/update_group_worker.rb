# frozen_string_literal: true

module Ci
  module PendingBuilds
    class UpdateGroupWorker
      include ApplicationWorker
      include PipelineBackgroundQueue

      data_consistency :always
      idempotent!

      def perform(group_id, update_params)
        ::Group.find_by_id(group_id).try do |group|
          ::Ci::UpdateGroupPendingBuildService.new(group, update_params).execute
        end
      end
    end
  end
end
