class Projects::ProjectAccessRequestsController < Projects::ApplicationController
  before_action :authorize_admin_project_member!, except: [:create, :withdraw]

  def create
    access_requestable.request_access(current_user)

    redirect_to access_requestable,
                notice: 'Your request for access has been queued for review.'
  end

  def withdraw
    access_requestable.withdraw_access_request(current_user)

    redirect_to access_requestable,
                notice: "Your access request to the #{source_type} has been withdrawn."
  end

  protected

  def access_request_params
    params.require(:project_access_request).permit(:user_id)
  end

  def source_type
    @source_type ||= access_requestable.class.to_s.humanize(capitalize: false)
  end

  # AccessRequestableActions concern
  alias_method :access_requestable, :project
end
