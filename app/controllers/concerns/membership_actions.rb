# frozen_string_literal: true

module MembershipActions
  include MembersPresentation
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_user!, only: :request_access
    before_action :already_a_member!, only: :request_access
  end

  def update
    member = members_and_requesters.find(params[:id])
    result = Members::UpdateService
      .new(current_user, update_params)
      .execute(member)

    if result[:status] == :success
      render json: update_success_response(result)
    else
      render json: { message: result[:message] }, status: :unprocessable_entity
    end
  end

  def destroy
    member = members_and_requesters.find(params[:id])
    skip_subresources = !ActiveRecord::Type::Boolean.new.cast(params.delete(:remove_sub_memberships))
    # !! is used in case unassign_issuables contains empty string which would result in nil
    unassign_issuables = !!ActiveRecord::Type::Boolean.new.cast(params.delete(:unassign_issuables))

    Members::DestroyService.new(current_user).execute(
      member,
      skip_subresources: skip_subresources,
      unassign_issuables: unassign_issuables
    )

    respond_to do |format|
      format.html do
        message =
          case membershipable
          when Namespace
            if skip_subresources
              _("User was successfully removed from group.")
            else
              _("User was successfully removed from group and any subgroups and projects.")
            end
          else
            _("User was successfully removed from project.")
          end

        redirect_to members_page_url, notice: message, status: :see_other
      end

      format.js { head :ok }
    end
  end

  def request_access
    access_requester = membershipable.request_access(current_user)

    if access_requester.persisted?
      redirect_to polymorphic_path(membershipable),
        notice: _('Your request for access has been queued for review.')
    else
      redirect_to polymorphic_path(membershipable),
        alert: format(
          _("Your request for access could not be processed: %{error_message}"),
          error_message: access_requester.errors.full_messages.to_sentence
        )
    end
  end

  def approve_access_request
    access_requester = requesters.find(params[:id])
    Members::ApproveAccessRequestService
      .new(current_user, params)
      .execute(access_requester)

    redirect_to members_page_url
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def leave
    member = members_and_requesters.find_by!(user_id: current_user.id)
    Members::DestroyService.new(current_user).execute(member)

    notice =
      if member.request?
        format(_("Your access request to the %{source_type} has been withdrawn."), source_type: source_type)
      else
        format(
          _("You left the \"%{membershipable_human_name}\" %{source_type}."),
          membershipable_human_name: membershipable.human_name,
          source_type: source_type
        )
      end

    respond_to do |format|
      format.html do
        redirect_path = member.request? ? member.source : [:dashboard, membershipable.class.to_s.tableize.to_sym]
        redirect_to redirect_path, notice: notice
      end

      format.json { render json: { notice: notice } }
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def resend_invite
    member = membershipable_members.find(params[:id])

    if member.invite?
      member.resend_invite

      redirect_to members_page_url, notice: _('The invitation was successfully resent.')
    else
      redirect_to members_page_url, alert: _('The invitation has already been accepted.')
    end
  end

  protected

  def membershipable
    raise NotImplementedError
  end

  def membershipable_members
    raise NotImplementedError
  end

  def root_params_key
    raise NotImplementedError
  end

  def members_page_url
    raise NotImplementedError
  end

  def source_type
    raise NotImplementedError
  end

  def plain_source_type
    raise NotImplementedError
  end

  def source
    raise NotImplementedError
  end

  def members_and_requesters
    membershipable.members_and_requesters
  end

  def requesters
    membershipable.requesters
  end

  def update_params
    params.require(root_params_key).permit(:access_level, :expires_at).merge({ source: source })
  end

  def requested_relations(inherited_permissions = :with_inherited_permissions)
    case params[inherited_permissions].presence
    when 'exclude'
      [:direct]
    when 'only'
      [:inherited].concat(shared_members_relations)
    else
      [:inherited, :direct].concat(shared_members_relations)
    end
  end

  def authenticate_user!
    return if current_user

    store_location_for :user, request.fullpath
    redirect_to new_user_session_path
  end

  def already_a_member!
    member = members.with_user(current_user)
    if member.present?
      redirect_to polymorphic_path(membershipable), notice: _('You already have access.')
    else
      requester = requesters.with_user(current_user)
      return unless requester.present?

      redirect_to polymorphic_path(membershipable), notice: _('You have already requested access.')
    end
  end

  private

  def update_success_response(result)
    member = result[:members].first
    if member.expires?
      {
        expires_soon: member.expires_soon?,
        expires_at_formatted: member.expires_at.to_time.in_time_zone.to_fs(:medium)
      }
    else
      {}
    end
  end

  def shared_members_relations
    project_relations = [:invited_groups, :shared_into_ancestors]
    [:shared_from_groups, *(project_relations if params[:project_id])]
  end
end

MembershipActions.prepend_mod_with('MembershipActions')
