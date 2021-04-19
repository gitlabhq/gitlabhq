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

  ALLOWED_SORT_VALUES = %w[id iid created_at updated_at ref finished_at].freeze
  DEFAULT_SORT_VALUE = 'id'

  ALLOWED_SORT_DIRECTIONS = %w[asc desc].freeze
  DEFAULT_SORT_DIRECTION = 'asc'

  def initialize(params = {})
    @params = params
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

  def init_collection
    if params[:project]
      params[:project].deployments
    else
      Deployment.none
    end
  end

  def sort(items)
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
    if params[:environment].present?
      items.for_environment_name(params[:environment])
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

  def sort_params
    order_by = ALLOWED_SORT_VALUES.include?(params[:order_by]) ? params[:order_by] : DEFAULT_SORT_VALUE
    order_direction = ALLOWED_SORT_DIRECTIONS.include?(params[:sort]) ? params[:sort] : DEFAULT_SORT_DIRECTION

    { order_by => order_direction }.tap do |sort_values|
      sort_values['id'] = 'desc' if sort_values['updated_at']
      sort_values['id'] = sort_values.delete('created_at') if sort_values['created_at'] # Sorting by `id` produces the same result as sorting by `created_at`
    end
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

DeploymentsFinder.prepend_if_ee('EE::DeploymentsFinder')
