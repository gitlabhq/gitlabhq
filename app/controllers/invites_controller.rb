# frozen_string_literal: true

class InvitesController < ApplicationController
  include Gitlab::Utils::StrongMemoize

  prepend_before_action :authenticate_user!, :track_invite_join_click, only: :show
  before_action :member
  before_action :ensure_member_exists
  before_action :invite_details
  skip_before_action :authenticate_user!, only: :decline

  helper_method :member?, :current_user_matches_invite?

  respond_to :html

  feature_category :system_access

  def show
    accept if skip_invitation_prompt?
  end

  def accept
    if current_user_matches_invite? && member.accept_invite!(current_user)
      redirect_to invite_details[:path], notice: helpers.invite_accepted_notice(member)
    else
      redirect_back_or_default(options: { alert: _("The invitation could not be accepted.") })
    end
  end

  def decline
    if member.decline_invite!
      return render layout: 'minimal' if !current_user && member.invite_to_unknown_user? && member.created_by

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
    current_user.verified_email?(@member.invite_email)
  end

  def member?
    @member.source.has_user?(current_user)
  end
  strong_memoize_attr :member?

  def member
    @token = params[:id].to_s
    Member.find_by_invite_token(@token)
  end
  strong_memoize_attr :member

  def ensure_member_exists
    return if member

    redirect_back_or_default(options: { alert: _("The invitation can not be found with the provided invite token.") })
  end

  def track_invite_join_click
    return unless member && initial_invite_email?

    Gitlab::Tracking.event(self.class.name, 'join_clicked', label: 'invite_email')
  end

  def authenticate_user!
    return if current_user

    if user_sign_up?
      set_session_invite_params

      redirect_to new_user_registration_path(invite_email: member.invite_email),
        notice: _("To accept this invitation, create an account or sign in.")
    else
      redirect_to new_user_session_path(sign_in_redirect_params), notice: sign_in_notice
    end
  end

  def set_session_invite_params
    session[:invite_email] = member.invite_email

    session[:originating_member_id] = member.id if initial_invite_email?
  end

  def initial_invite_email?
    params[:invite_type] == ::Members::InviteMailer::INITIAL_INVITE
  end

  def sign_in_redirect_params
    member ? { invite_email: member.invite_email } : {}
  end

  def user_sign_up?
    Gitlab::CurrentSettings.allow_signup? && member && !User.find_by_any_email(member.invite_email)
  end

  def sign_in_notice
    if Gitlab::CurrentSettings.allow_signup?
      _("To accept this invitation, sign in or create an account.")
    else
      _("To accept this invitation, sign in.")
    end
  end

  def invite_details
    @invite_details ||= case member.source
                        when Project
                          {
                            name: member.source.full_name,
                            url: project_url(member.source),
                            title: _("project"),
                            path: project_path(member.source)
                          }
                        when Group
                          {
                            name: member.source.name,
                            url: group_url(member.source),
                            title: _("group"),
                            path: group_path(member.source)
                          }
                        end
  end
end
