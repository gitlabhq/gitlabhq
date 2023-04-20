# frozen_string_literal: true

class IssuableExportCsvWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  data_consistency :always

  sidekiq_options retry: 3

  feature_category :team_planning
  worker_resource_boundary :cpu
  loggable_arguments 0, 1, 2, 3

  def perform(type, current_user_id, project_id, params)
    user = User.find(current_user_id)
    project = Project.find(project_id)

    export_service(type, user, project, params).email(user)
  rescue ActiveRecord::RecordNotFound => error
    logger.error("Failed to export CSV (current_user_id:#{current_user_id}, project_id:#{project_id}): #{error.message}")
  end

  private

  def export_service(type, user, project, params)
    issuable_classes = issuable_classes_for(type.to_sym)
    issuables = issuable_classes[:finder].new(user, parse_params(params, project.id, type)).execute

    if type.to_sym == :issue # issues do not support field selection for export
      issuable_classes[:service].new(issuables, project, user)
    else
      fields = params.with_indifferent_access.delete(:selected_fields) || []
      issuable_classes[:service].new(issuables, project, fields)
    end
  end

  def issuable_classes_for(type)
    case type
    when :issue
      { finder: IssuesFinder, service: Issues::ExportCsvService }
    when :merge_request
      { finder: MergeRequestsFinder, service: MergeRequests::ExportCsvService }
    when :work_item
      { finder: WorkItems::WorkItemsFinder, service: WorkItems::ExportCsvService }
    else
      raise ArgumentError, type_error_message(type)
    end
  end

  def parse_params(params, project_id, _type)
    params
      .with_indifferent_access
      .except(:sort)
      .merge(project_id: project_id)
  end

  def type_error_message(type)
    types_sentence = allowed_types.to_sentence(last_word_connector: ' or ')

    "Type parameter must be #{types_sentence}, it was #{type}"
  end

  def allowed_types
    %w[:issue :merge_request :work_item]
  end
end

IssuableExportCsvWorker.prepend_mod_with('IssuableExportCsvWorker')
