class Import::BaseController < ApplicationController
  private

  def find_or_create_namespace(name, owner)
    return current_user.namespace if name == owner
    return current_user.namespace unless current_user.can_create_group?

    begin
      name = params[:target_namespace].presence || name
      namespace = Group.create!(name: name, path: name, owner: current_user)
      namespace.add_owner(current_user)
      namespace
    rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
      Namespace.find_by_path_or_name(name)
    end
  end
end
