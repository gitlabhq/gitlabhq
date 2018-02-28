class Admin::ProjectsFinder
  attr_reader :sort, :namespace_id, :visibility_level, :with_push,
              :abandoned, :last_repository_check_failed, :archived,
              :personal, :name, :page, :current_user

  def initialize(params:, current_user:)
    @current_user = current_user
    @sort = params.fetch(:sort) { 'latest_activity_desc' }
    @namespace_id = params[:namespace_id]
    @visibility_level = params[:visibility_level]
    @with_push = params[:with_push]
    @abandoned = params[:abandoned]
    @last_repository_check_failed = params[:last_repository_check_failed]
    @archived = params[:archived]
    @personal = params[:personal]
    @name = params[:name]
    @page = params[:page]
  end

  def execute
    items = Project.with_statistics
    items = items.in_namespace(namespace_id) if namespace_id.present?
    items = items.where(visibility_level: visibility_level) if visibility_level.present?
    items = items.with_push if with_push.present?
    items = items.abandoned if abandoned.present?
    items = items.where(last_repository_check_failed: true) if last_repository_check_failed.present?
    items = items.non_archived unless archived.present?
    items = items.personal(current_user) if personal.present?
    items = items.search(name) if name.present?
    items = items.sort(sort)
    items.includes(:namespace).order("namespaces.path, projects.name ASC").page(page)
  end
end
