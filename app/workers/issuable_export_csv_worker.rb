# frozen_string_literal: true

class IssuableExportCsvWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  feature_category :issue_tracking
  worker_resource_boundary :cpu
  loggable_arguments 2

  PERMITTED_TYPES = [:merge_request, :issue].freeze

  def perform(type, current_user_id, project_id, params)
    @type = type.to_sym
    check_permitted_type!
    process_params!(params, project_id)

    @current_user = User.find(current_user_id)
    @project = Project.find(project_id)
    @service = service(find_objects(params))

    @service.email(@current_user)
  end

  private

  def find_objects(params)
    case @type
    when :issue
      IssuesFinder.new(@current_user, params).execute
    when :merge_request
      MergeRequestsFinder.new(@current_user, params).execute
    end
  end

  def service(issuables)
    case @type
    when :issue
      Issues::ExportCsvService.new(issuables, @project)
    when :merge_request
      MergeRequests::ExportCsvService.new(issuables, @project)
    end
  end

  def process_params!(params, project_id)
    params.symbolize_keys!
    params[:project_id] = project_id
    params.delete(:sort)
  end

  def check_permitted_type!
    raise ArgumentError, "type parameter must be :issue or :merge_request, it was #{@type}" unless PERMITTED_TYPES.include?(@type)
  end
end
