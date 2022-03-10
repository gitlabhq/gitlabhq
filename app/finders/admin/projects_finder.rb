# frozen_string_literal: true

class Admin::ProjectsFinder
  attr_reader :params, :current_user

  def initialize(params:, current_user:)
    @params = params
    @current_user = current_user
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def execute
    items = Project.without_deleted.with_statistics.with_route
    items = by_namespace_id(items)
    items = by_visibility_level(items)
    items = by_with_push(items)
    items = by_abandoned(items)
    items = by_last_repository_check_failed(items)
    items = by_archived(items)
    items = by_personal(items)
    items = by_name(items)
    items = items.includes(namespace: [:owner, :route])
    sort(items).page(params[:page])
  end
  # rubocop: enable CodeReuse/ActiveRecord

  private

  def by_namespace_id(items)
    params[:namespace_id].present? ? items.in_namespace(params[:namespace_id]) : items
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def by_visibility_level(items)
    params[:visibility_level].present? ? items.where(visibility_level: params[:visibility_level]) : items
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def by_with_push(items)
    params[:with_push].present? ? items.with_push : items
  end

  def by_abandoned(items)
    params[:abandoned].present? ? items.abandoned : items
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def by_last_repository_check_failed(items)
    params[:last_repository_check_failed].present? ? items.where(last_repository_check_failed: true) : items
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def by_archived(items)
    if params[:archived] == 'only'
      items.archived
    elsif params[:archived].blank?
      items.non_archived
    else
      items
    end
  end

  def by_personal(items)
    params[:personal].present? ? items.personal(current_user) : items
  end

  def by_name(items)
    params[:name].present? ? items.search(params[:name]) : items
  end

  def sort(items)
    sort = params.fetch(:sort, 'latest_activity_desc')
    items.sort_by_attribute(sort)
  end
end
