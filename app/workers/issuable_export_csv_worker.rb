# frozen_string_literal: true

class IssuableExportCsvWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  feature_category :issue_tracking
  worker_resource_boundary :cpu
  loggable_arguments 2

  def perform(type, current_user_id, project_id, params)
    user = User.find(current_user_id)
    project = Project.find(project_id)
    finder_params = map_params(params, project_id)

    export_service(type.to_sym, user, project, finder_params).email(user)
  rescue ActiveRecord::RecordNotFound => error
    logger.error("Failed to export CSV (current_user_id:#{current_user_id}, project_id:#{project_id}): #{error.message}")
  end

  private

  def map_params(params, project_id)
    params
      .symbolize_keys
      .except(:sort)
      .merge(project_id: project_id)
  end

  def export_service(type, user, project, params)
    issuable_class = service_classes_for(type)
    issuables = issuable_class[:finder].new(user, params).execute
    issuable_class[:service].new(issuables, project)
  end

  def service_classes_for(type)
    case type
    when :issue
      { finder: IssuesFinder, service: Issues::ExportCsvService }
    when :merge_request
      { finder: MergeRequestsFinder, service: MergeRequests::ExportCsvService }
    else
      raise ArgumentError, type_error_message(type)
    end
  end

  def type_error_message(type)
    "Type parameter must be :issue or :merge_request, it was #{type}"
  end
end

IssuableExportCsvWorker.prepend_if_ee('::EE::IssuableExportCsvWorker')
