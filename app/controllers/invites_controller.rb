class InvitesController < ApplicationController
  before_action :member
  skip_before_action :authenticate_user!, only: :decline

  respond_to :html

  def show

  end

  def accept
    if member.accept_invite!(current_user)
      label, path = source_info(member.source)

      redirect_to path, notice: "You have been granted #{member.human_access} access to #{label}."
    else
      redirect_to :back, alert: "The invitation could not be accepted."
    end
  end

  def decline
    if member.decline_invite!
      label, _ = source_info(member.source)

      path =
        if current_user
          dashboard_projects_path
        else
          new_user_session_path
        end

      redirect_to path, notice: "You have declined the invitation to join #{label}."
    else
      redirect_to :back, alert: "The invitation could not be declined."
    end
  end

  private

  def member
    return @member if defined?(@member)

    @token = params[:id]
    @member = Member.find_by_invite_token(@token)

    unless @member
      render_404 and return
    end

    @member
  end

  def authenticate_user!
    return if current_user

    notice = "To accept this invitation, sign in"
    notice << " or create an account" if current_application_settings.signup_enabled?
    notice << "."

    store_location_for :user, request.fullpath
    redirect_to new_user_session_path, notice: notice
  end

  def source_info(source)
    case source
    when Project
      project = member.source
      label = "project #{project.name_with_namespace}"
      path = namespace_project_path(project.namespace, project)
    when Group
      group = member.source
      label = "group #{group.name}"
      path = group_path(group)
    else
      label = "who knows what"
      path = dashboard_projects_path
    end

    [label, path]
  end
end
