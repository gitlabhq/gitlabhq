# frozen_string_literal: true

module MergeRequests
  class KeepAroundRefsWorker
    include ApplicationWorker

    data_consistency :sticky

    sidekiq_options retry: 20

    feature_category :code_review_workflow
    urgency :high
    defer_on_database_health_signal :gitlab_main, [:none], 1.minute
    idempotent!

    def perform(project_ids, shas, source)
      project_ids = Array(project_ids).compact
      shas = Array(shas).compact

      unless project_ids.present? && shas.present?
        logger.info(structured_payload(
          message: 'Missing required parameters.',
          project_ids: project_ids,
          shas: shas
        ))
        return
      end

      MergeRequests::KeepAroundRefsService.new(
        project_ids: project_ids,
        shas: shas,
        source: source
      ).execute
    end
  end
end
