# frozen_string_literal: true

class RunnerJobsFinder
  attr_reader :runner, :params

  ALLOWED_INDEXED_COLUMNS = %w[id created_at].freeze

  def initialize(runner, params = {})
    @runner = runner
    @params = params
  end

  def execute
    items = @runner.builds
    items = by_status(items)
    sort_items(items)
  end

  private

  # rubocop: disable CodeReuse/ActiveRecord
  def by_status(items)
    return items unless HasStatus::AVAILABLE_STATUSES.include?(params[:status])

    items.where(status: params[:status])
  end
  # rubocop: enable CodeReuse/ActiveRecord

  # rubocop: disable CodeReuse/ActiveRecord
  def sort_items(items)
    order_by = if ALLOWED_INDEXED_COLUMNS.include?(params[:order_by])
                 params[:order_by]
               else
                 :id
               end

    sort = if params[:sort] =~ /\A(ASC|DESC)\z/i
             params[:sort]
           else
             :desc
           end

    items.order(order_by => sort)
  end
  # rubocop: enable CodeReuse/ActiveRecord
end
