# frozen_string_literal: true

class Vulnerabilities::FeedbackEntity < Grape::Entity
  include RequestAwareEntity

  expose :id
  expose :created_at
  expose :project_id
  expose :author, using: UserEntity
  expose :comment_details, if: -> (feedback, _) { feedback.has_comment? } do
    expose :comment
    expose :comment_timestamp
    expose :comment_author, using: UserEntity
  end

  expose :pipeline, if: -> (feedback, _) { feedback.pipeline.present? } do
    expose :id do |feedback|
      feedback.pipeline.id
    end

    expose :path do |feedback|
      project_pipeline_path(feedback.pipeline.project, feedback.pipeline)
    end
  end

  expose :issue_iid, if: -> (feedback, _) { feedback.issue.present? } do |feedback|
    feedback.issue.iid
  end

  expose :issue_url, if: -> (_, _) { can_read_issue? } do |feedback|
    project_issue_url(feedback.project, feedback.issue)
  end

  expose :merge_request_iid, if: -> (feedback, _) { feedback.merge_request.present? } do |feedback|
    feedback.merge_request.iid
  end

  expose :merge_request_path, if: -> (_, _) { can_read_merge_request? } do |feedback|
    project_merge_request_path(feedback.project, feedback.merge_request)
  end

  expose :destroy_vulnerability_feedback_dismissal_path, if: ->(_, _) { can_destroy_feedback? }

  expose :category
  expose :feedback_type
  expose :branch do |feedback|
    feedback&.pipeline&.ref
  end
  expose :project_fingerprint

  alias_method :feedback, :object

  private

  def destroy_vulnerability_feedback_dismissal_path
    project_vulnerability_feedback_path(feedback.project, feedback)
  end

  def can_destroy_feedback?
    can?(current_user, :destroy_vulnerability_feedback, feedback)
  end

  def can_read_issue?
    feedback.issue.present? && can?(current_user, :read_issue, feedback.issue)
  end

  def can_read_merge_request?
    feedback.merge_request.present? && can?(current_user, :read_merge_request, feedback.merge_request)
  end

  def current_user
    return request.current_user if request.respond_to?(:current_user)
  end
end
