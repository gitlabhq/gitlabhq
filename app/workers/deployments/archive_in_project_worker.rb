# frozen_string_literal: true

module Deployments
  class ArchiveInProjectWorker
    include ApplicationWorker

    queue_namespace :deployment
    feature_category :continuous_delivery
    idempotent!
    deduplicate :until_executed, including_scheduled: true
    data_consistency :delayed

    def perform(project_id)
      Project.find_by_id(project_id).try do |project|
        Deployments::ArchiveInProjectService.new(project, nil).execute
      end
    end
  end
end
