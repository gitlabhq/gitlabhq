class Import::BaseController < ApplicationController

  private

  def get_or_create_namespace
    begin
      namespace = Group.create!(name: @target_namespace, path: @target_namespace, owner: current_user)
      namespace.add_owner(current_user)
    rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
      namespace = Namespace.find_by_path_or_name(@target_namespace)
      unless current_user.can?(:create_projects, namespace)
        @already_been_taken = true
        return false
      end
    end

    namespace
  end
end
