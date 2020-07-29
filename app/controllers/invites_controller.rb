# frozen_string_literal: true

class InvitesController < ApplicationController
  include Gitlab::Utils::StrongMemoize

  before_action :member
  before_action :invite_details
  skip_before_action :authenticate_user!, only: :decline

  helper_method :member?, :current_user_matches_invite?

  respond_to :html

  def show
    accept if skip_invitation_prompt?
  end

  def accept
    if member.accept_invite!(current_user)
      redirect_to invite_details[:path], notice: _("You have been granted %{member_human_access} access to %{title} %{name}.") %
        { member_human_access: member.human_access, title: invite_details[:title], name: invite_details[:name] }
    else
      redirect_back_or_default(options: { alert: _("The invitation could not be accepted.") })
    end
  end

  def decline
    if member.decline_invite!
      path =
        if current_user
          dashboard_projects_path
        else
          new_user_session_path
        end

      redirect_to path, notice: _("You have declined the invitation to join %{title} %{name}.") %
        { title: invite_details[:title], name: invite_details[:name] }
    else
      redirect_back_or_default(options: { alert: _("The invitation could not be declined.") })
    end
  end

  private

  def skip_invitation_prompt?
    !member? && current_user_matches_invite?
  end

  def current_user_matches_invite?
    @member.invite_email == current_user.email
  end

  def member?
    strong_memoize(:is_member) do
      @member.source.users.include?(current_user)
    end
  end

  def member
    return @member if defined?(@member)

    @token = params[:id]
    @member = Member.find_by_invite_token(@token)

    return render_404 unless @member

    @member
  end

  def authenticate_user!
    return if current_user

    notice = ["To accept this invitation, sign in"]
    notice << "or create an account" if Gitlab::CurrentSettings.allow_signup?
    notice = notice.join(' ') + "."

    store_location_for :user, request.fullpath
    redirect_to new_user_session_path, notice: notice
  end

  def invite_details
    @invite_details ||= case @member.source
                        when Project
                          {
                            name: @member.source.full_name,
                            url: project_url(@member.source),
                            title: _("project"),
                            path: project_path(@member.source)
                          }
                        when Group
                          {
                            name: @member.source.name,
                            url: group_url(@member.source),
                            title: _("group"),
                            path: group_path(@member.source)
                          }
                        end
  end
end
