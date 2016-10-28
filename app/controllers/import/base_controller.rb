class Import::BaseController < ApplicationController
  private

  def find_or_create_namespace
    path = params[:target_namespace]

    return current_user.namespace if path == current_user.namespace_path

    owned_namespace = current_user.owned_groups.find_by_full_path(path)
    return owned_namespace if owned_namespace

    return current_user.namespace unless current_user.can_create_group?

    path.split('/').inject(nil) do |parent, name|
      begin
        namespace = Group.create!(name: name,
                                  path: name,
                                  owner: current_user,
                                  parent: parent)
        namespace.add_owner(current_user)

        namespace
      rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
        # Namespace.where(parent: parent).find_by_path_or_name(name)
        current_user.namespace
      end
    end
  end
end
