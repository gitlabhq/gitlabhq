class NamespacesController < ApplicationController
  skip_before_filter :authenticate_user!

  def show
    namespace = Namespace.find_by(path: params[:id])

    unless namespace
      return render_404
    end

    if namespace.type == "Group"
      redirect_to group_path(namespace)
    else
      redirect_to user_path(namespace.owner)
    end
  end
end

