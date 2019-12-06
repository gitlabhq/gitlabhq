# frozen_string_literal: true

class DeploymentsFinder
  attr_reader :project, :params

  ALLOWED_SORT_VALUES = %w[id iid created_at updated_at ref].freeze
  DEFAULT_SORT_VALUE = 'id'.freeze

  ALLOWED_SORT_DIRECTIONS = %w[asc desc].freeze
  DEFAULT_SORT_DIRECTION = 'asc'.freeze

  def initialize(project, params = {})
    @project = project
    @params = params
  end

  def execute
    items = init_collection
    items = by_updated_at(items)
    sort(items)
  end

  private

  # rubocop: disable CodeReuse/ActiveRecord
  def init_collection
    project
      .deployments
      .includes(
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

  # rubocop: disable CodeReuse/ActiveRecord
  def sort(items)
    items.order(sort_params)
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def by_updated_at(items)
    items = items.updated_before(params[:updated_before]) if params[:updated_before].present?
    items = items.updated_after(params[:updated_after]) if params[:updated_after].present?

    items
  end

  def sort_params
    order_by = ALLOWED_SORT_VALUES.include?(params[:order_by]) ? params[:order_by] : DEFAULT_SORT_VALUE
    order_direction = ALLOWED_SORT_DIRECTIONS.include?(params[:sort]) ? params[:sort] : DEFAULT_SORT_DIRECTION

    { order_by => order_direction }.tap do |sort_values|
      sort_values['id'] = 'desc' if sort_values['updated_at']
      sort_values['id'] = sort_values.delete('created_at') if sort_values['created_at'] # Sorting by `id` produces the same result as sorting by `created_at`
    end
  end
end
