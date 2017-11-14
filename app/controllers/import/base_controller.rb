class Import::BaseController < ApplicationController
  private

  def find_or_create_namespace(namespace_path, client_username)
    if params[:target_namespace].present?
      namespace_path = params[:target_namespace]
    elsif namespace_path == client_username
      return current_user.namespace
    end

    namespace = Namespace.find_by_full_path(namespace_path)
    return namespace if namespace

    Groups::NestedCreateService.new(current_user, group_path: namespace_path).execute
  end
end
