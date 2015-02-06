class Import::BaseController < ApplicationController

  private

  def get_or_create_namespace
    existing_namespace = Namespace.find_by("path = ? OR name = ?", @target_namespace, @target_namespace)

    if existing_namespace
      if existing_namespace.owner == current_user
        namespace = existing_namespace
      else
        @already_been_taken = true
        return false
      end
    else
      namespace = Group.create(name: @target_namespace, path: @target_namespace, owner: current_user)
      namespace.add_owner(current_user)
      namespace
    end
  end
end
