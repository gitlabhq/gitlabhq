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

  def deny
    access_requester = User.find_by!(username: deny_username)

    access_requestable.deny_access_request(access_requester, current_user)

    respond_to do |format|
      format.html do
        redirect_to project_members_path(access_requestable),
                    notice: "User #{deny_username} was denied access to the #{access_requestable.human_name} #{source_type}."
      end

      format.js { head :ok }
    end
  end

  protected

  def deny_username
    params.require(:username)
  end

  def source_type
    @source_type ||= access_requestable.class.to_s.humanize(capitalize: false)
  end

  # AccessRequestableActions concern
  alias_method :access_requestable, :project
end
