class NamespacesController < ApplicationController
  skip_before_action :authenticate_user!

  def show
    namespace = Namespace.find_by(path: params[:id])

    if namespace
      if namespace.is_a?(Group)
        group = namespace
      else
        user = namespace.owner
      end
    end

    if user
      redirect_to user_path(user)
    elsif group
      redirect_to group_path(group)
    elsif current_user.nil?
      authenticate_user!
    else
      render_404
    end
  end
end
