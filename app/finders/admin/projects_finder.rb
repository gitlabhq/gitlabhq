class Admin::ProjectsFinder
  attr_reader :params, :current_user

  def initialize(params:, current_user:)
    @params = params
    @current_user = current_user
  end

  def execute
    items = Project.without_deleted.with_statistics
    items = by_namespace_id(items)
    items = by_visibilty_level(items)
    items = by_with_push(items)
    items = by_abandoned(items)
    items = by_last_repository_check_failed(items)
    items = by_archived(items)
    items = by_personal(items)
    items = by_name(items)
    sort(items).page(params[:page])
  end

  private

  def by_namespace_id(items)
    params[:namespace_id].present? ? items.in_namespace(params[:namespace_id]) : items
  end

  def by_visibilty_level(items)
    params[:visibility_level].present? ? items.where(visibility_level: params[:visibility_level]) : items
  end

  def by_with_push(items)
    params[:with_push].present? ? items.with_push : items
  end

  def by_abandoned(items)
    params[:abandoned].present? ? items.abandoned : items
  end

  def by_last_repository_check_failed(items)
    params[:last_repository_check_failed].present? ? items.where(last_repository_check_failed: true) : items
  end

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
    sort = params.fetch(:sort) { 'latest_activity_desc' }
    items.sort(sort)
  end
end
