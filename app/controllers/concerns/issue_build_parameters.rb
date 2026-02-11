# frozen_string_literal: true

module IssueBuildParameters
  extend ActiveSupport::Concern
  include ::Gitlab::Utils::StrongMemoize

  def build_params
    allowed_params = params.permit(
      :discussion_to_resolve,
      :add_related_issue,
      :merge_request_to_resolve_discussions_of,
      :observability_log_details,
      :observability_metric_details,
      :observability_trace_details
    )

    issue_params.merge(
      merge_request_to_resolve_discussions_of: allowed_params[:merge_request_to_resolve_discussions_of],
      discussion_to_resolve: allowed_params[:discussion_to_resolve],
      confidential: !!Gitlab::Utils.to_boolean(issue_params[:confidential]),
      observability_links: {
        metrics: allowed_params[:observability_metric_details],
        logs: allowed_params[:observability_log_details],
        tracing: allowed_params[:observability_trace_details]
      }).tap(&:permit!)
  end

  # Overriden in EE
  def issue_params
    allowed_params ||= params.permit(:issue_type, issue: issue_attributes)
    issue_params = allowed_params[:issue] || ActionController::Parameters.new(assignee_ids: "")

    issue_params[:issue_type] ||= allowed_params[:issue_type]
    issue_params.delete(:issue_type) unless allowed_issue_type?(issue_params[:issue_type])

    issue_params
  end

  private

  # Overriden on EE
  def issue_attributes
    [
      :title,
      :assignee_id,
      :position,
      :description,
      :confidential,
      :milestone_id,
      :due_date,
      :state_event,
      :task_num,
      :lock_version,
      :discussion_locked,
      :issue_type,
      {
        label_ids: [],
        assignee_ids: [],
        update_task: [:index, :checked, :line_number, :line_source, :line_sourcepos],
        sentry_issue_attributes: [:sentry_issue_identifier]
      }
    ]
  end

  def allowed_issue_type?(issue_type)
    ::WorkItems::TypesFilter.allowed_types_for_issues.include?(issue_type.to_s)
  end

  def vulnerability
    project.vulnerabilities.find(vulnerability_id) if vulnerability_id
  end
  strong_memoize_attr :vulnerability

  def vulnerability_id
    params.permit(:vulnerability_id)[:vulnerability_id] if can?(current_user, :read_security_resource, project)
  end
  strong_memoize_attr :vulnerability_id
end

::IssueBuildParameters.prepend_mod
