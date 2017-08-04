class Projects::ProjectAccessRequestsController < Projects::ApplicationController
  before_action :authorize_admin_project_member!, except: [:create]

  def create
    access_requestable.request_access(current_user)

    redirect_to access_requestable,
                notice: 'Your request for access has been queued for review.'
  end

  protected

  def access_request_params
    params.require(:project_access_request).permit(:user_id)
  end

  # AccessRequestableActions concern
  alias_method :access_requestable, :project
end
