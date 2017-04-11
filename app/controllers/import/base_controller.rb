class Import::BaseController < ApplicationController
  private

  def find_or_create_namespace(names, owner)
    return current_user.namespace if names == owner
    return current_user.namespace unless current_user.can_create_group?

    names = params[:target_namespace].presence || names
    full_path_namespace = Namespace.find_by_full_path(names)

    return full_path_namespace if full_path_namespace

    names.split('/').inject(nil) do |parent, name|
      begin
        namespace = Group.create!(name: name,
                                  path: name,
                                  owner: current_user,
                                  parent: parent)
        namespace.add_owner(current_user)

        namespace
      rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
        Namespace.where(parent: parent).find_by_path_or_name(name)
      end
    end
  end
end
