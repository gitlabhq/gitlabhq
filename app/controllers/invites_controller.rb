class InvitesController < ApplicationController
  before_filter :member

  respond_to :html

  layout 'navless'

  def show

  end

  def accept
    if member.accept_invite!(current_user)
      case member.source
      when Project
        project = member.source
        source = "project #{project.name_with_namespace}"
        path = namespace_project_path(project.namespace, project)
      when Group
        group = member.source
        source = "group #{group.name}"
        path = group_path(group)
      else
        source = "who knows what"
        path = dashboard_path
      end

      redirect_to path, notice: "You have been granted #{member.human_access} access to #{source}."
    else
      redirect_to :back, alert: "The invite could not be accepted."
    end
  end

  private

  def member
    return @member if defined?(@member)
    
    @token = params[:id]
    if member = Member.find_by_invite_token(@token)
      @member = member
    else
      render_404
    end
  end

  def authenticate_user!
    return if current_user

    notice = "To accept this invitation, sign in"
    notice << " or create an account" if current_application_settings.signup_enabled?
    notice << "."

    store_location_for :user, request.fullpath
    redirect_to new_user_session_path, notice: notice
  end
end
