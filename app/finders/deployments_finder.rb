# frozen_string_literal: true

# WARNING: This finder does not check permissions!
#
# Arguments:
#   params:
#     project: Project model - Find deployments for this project
#     updated_after: DateTime
#     updated_before: DateTime
#     finished_after: DateTime
#     finished_before: DateTime
#     environment: String
#     status: String (see Deployment.statuses)
#     order_by: String (see ALLOWED_SORT_VALUES constant)
#     sort: String (asc | desc)
class DeploymentsFinder
  attr_reader :params

  # Warning:
  # These const are directly used in Deployment Rest API, thus
  # modifying these values could implicity change the API interface or introduce a breaking change.
  # Also, if you add a sort value, make sure that the new query will stay
  # performant with the other filtering/sorting parameters.
  # The composed query could be significantly slower when the filtering and sorting columns are different.
  # See https://gitlab.com/gitlab-org/gitlab/-/issues/325627 for example.
  ALLOWED_SORT_VALUES = %w[id iid created_at updated_at ref finished_at].freeze
  DEFAULT_SORT_VALUE = 'id'

  ALLOWED_SORT_DIRECTIONS = %w[asc desc].freeze
  DEFAULT_SORT_DIRECTION = 'asc'

  InefficientQueryError = Class.new(StandardError)

  def initialize(params = {})
    @params = params

    validate!
  end

  def execute
    items = init_collection
    items = by_updated_at(items)
    items = by_finished_at(items)
    items = by_environment(items)
    items = by_status(items)
    items = preload_associations(items)
    sort(items)
  end

  private

  def validate!
    if filter_by_updated_at? && filter_by_finished_at?
      raise InefficientQueryError, 'Both `updated_at` filter and `finished_at` filter can not be specified'
    end

    # Currently, the inefficient parameters are allowed in order to avoid breaking changes in Deployment API.
    # We'll switch to a hard error in https://gitlab.com/gitlab-org/gitlab/-/issues/328500.
    if (filter_by_updated_at? && !order_by_updated_at?) || (!filter_by_updated_at? && order_by_updated_at?)
      Gitlab::ErrorTracking.track_and_raise_for_dev_exception(
        InefficientQueryError.new('`updated_at` filter and `updated_at` sorting must be paired')
      )
    end

    if (filter_by_finished_at? && !order_by_finished_at?) || (!filter_by_finished_at? && order_by_finished_at?)
      raise InefficientQueryError, '`finished_at` filter and `finished_at` sorting must be paired'
    end

    if filter_by_finished_at? && !filter_by_successful_deployment?
      raise InefficientQueryError, '`finished_at` filter must be combined with `success` status filter.'
    end

    if params[:environment].present? && !params[:project].present?
      raise InefficientQueryError, '`environment` filter must be combined with `project` scope.'
    end
  end

  def init_collection
    if params[:project].present?
      params[:project].deployments
    elsif params[:group].present?
      ::Deployment.for_projects(params[:group].all_projects)
    else
      ::Deployment.none
    end
  end

  def sort(items)
    sort_params = build_sort_params
    optimize_sort_params!(sort_params)
    items.order(sort_params) # rubocop: disable CodeReuse/ActiveRecord
  end

  def by_updated_at(items)
    items = items.updated_before(params[:updated_before]) if params[:updated_before].present?
    items = items.updated_after(params[:updated_after]) if params[:updated_after].present?

    items
  end

  def by_finished_at(items)
    items = items.finished_before(params[:finished_before]) if params[:finished_before].present?
    items = items.finished_after(params[:finished_after]) if params[:finished_after].present?

    items
  end

  def by_environment(items)
    if params[:project].present? && params[:environment].present?
      items.for_environment_name(params[:project], params[:environment])
    else
      items
    end
  end

  def by_status(items)
    return items unless params[:status].present?

    unless Deployment.statuses.key?(params[:status])
      raise ArgumentError, "The deployment status #{params[:status]} is invalid"
    end

    items.for_status(params[:status])
  end

  def build_sort_params
    order_by = ALLOWED_SORT_VALUES.include?(params[:order_by]) ? params[:order_by] : DEFAULT_SORT_VALUE
    order_direction = ALLOWED_SORT_DIRECTIONS.include?(params[:sort]) ? params[:sort] : DEFAULT_SORT_DIRECTION

    { order_by => order_direction }
  end

  def optimize_sort_params!(sort_params)
    sort_direction = sort_params.each_value.first

    # Implicitly enforce the ordering when filtered by `updated_at` column for performance optimization.
    # See https://gitlab.com/gitlab-org/gitlab/-/issues/325627#note_552417509.
    # We remove this in https://gitlab.com/gitlab-org/gitlab/-/issues/328500.
    if filter_by_updated_at?
      sort_params.replace('updated_at' => sort_direction)
    end

    if sort_params['created_at'] || sort_params['iid']
      # Sorting by `id` produces the same result as sorting by `created_at` or `iid`
      sort_params.replace(id: sort_direction)
    elsif sort_params['updated_at']
      # This adds the order as a tie-breaker when multiple rows have the same updated_at value.
      # See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/20848.
      sort_params.merge!(id: sort_direction)
    end
  end

  def filter_by_updated_at?
    params[:updated_before].present? || params[:updated_after].present?
  end

  def filter_by_finished_at?
    params[:finished_before].present? || params[:finished_after].present?
  end

  def filter_by_successful_deployment?
    params[:status].to_s == 'success'
  end

  def order_by_updated_at?
    params[:order_by].to_s == 'updated_at'
  end

  def order_by_finished_at?
    params[:order_by].to_s == 'finished_at'
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def preload_associations(scope)
    scope.includes(
      :user,
      environment: [],
      deployable: {
        job_artifacts: [],
        pipeline: {
          project: {
            route: [],
            namespace: :route
          }
        },
        project: {
          namespace: :route
        }
      }
    )
  end
  # rubocop: enable CodeReuse/ActiveRecord
end
