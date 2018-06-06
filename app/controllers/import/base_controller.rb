class Import::BaseController < ApplicationController
  private

  def find_already_added_projects(import_type)
    current_user.created_projects.where(import_type: import_type).includes(:import_state)
  end

  def find_jobs(import_type)
    current_user.created_projects
      .includes(:import_state)
      .where(import_type: import_type)
      .to_json(only: [:id], methods: [:import_status])
  end

  def find_or_create_namespace(names, owner)
    names = params[:target_namespace].presence || names

    return current_user.namespace if names == owner

    group = Groups::NestedCreateService.new(current_user, group_path: names).execute

    group.errors.any? ? current_user.namespace : group
  rescue => e
    Gitlab::AppLogger.error(e)

    current_user.namespace
  end

  def project_save_error(project)
    project.errors.full_messages.join(', ')
  end
end
