# frozen_string_literal: true

module Ci
  module PendingBuilds
    class UpdateProjectWorker
      include ApplicationWorker
      include PipelineBackgroundQueue

      data_consistency :always
      idempotent!

      def perform(project_id, update_params)
        ::Project.find_by_id(project_id).try do |project|
          ::Ci::UpdatePendingBuildService.new(project, update_params).execute
        end
      end
    end
  end
end
