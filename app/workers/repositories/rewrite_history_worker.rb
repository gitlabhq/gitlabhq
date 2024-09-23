# frozen_string_literal: true

module Repositories
  class RewriteHistoryWorker
    include ApplicationWorker

    idempotent!
    deduplicate :until_executed
    data_consistency :sticky

    feature_category :source_code_management

    def perform(args = {})
      args = args.with_indifferent_access

      project = Project.find_by_id(args[:project_id])
      return unless project

      user = User.find_by_id(args[:user_id])
      return unless user

      Repositories::RewriteHistoryService.new(project, user).execute(
        blob_oids: args.fetch(:blob_oids, []),
        redactions: args.fetch(:redactions, [])
      )
    end
  end
end
