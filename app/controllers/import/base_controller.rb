class Import::BaseController < ApplicationController
  private

  def find_or_create_namespace(name, owner)
    begin
      @target_namespace = params[:new_namespace].presence || name
      @target_namespace = current_user.namespace_path if name == owner || !current_user.can_create_group?

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
