# frozen_string_literal: true

module MembershipActions
  include MembersPresentation
  extend ActiveSupport::Concern

  def create
    create_params = params.permit(:user_ids, :access_level, :expires_at)
    result = Members::CreateService.new(current_user, create_params.merge({ source: membershipable, invite_source: "#{plain_source_type}-members-page" })).execute

    if result[:status] == :success
      redirect_to members_page_url, notice: _('Users were successfully added.')
    else
      redirect_to members_page_url, alert: result[:message]
    end
  end

  def update
    update_params = params.require(root_params_key).permit(:access_level, :expires_at)
    member = membershipable.members_and_requesters.find(params[:id])
    result = Members::UpdateService
      .new(current_user, update_params)
      .execute(member)

    member = result[:member]

    member_data = if member.expires?
                    {
                      expires_in: helpers.distance_of_time_in_words_to_now(member.expires_at),
                      expires_soon: member.expires_soon?,
                      expires_at_formatted: member.expires_at.to_time.in_time_zone.to_s(:medium)
                    }
                  else
                    {}
                  end

    if result[:status] == :success
      render json: member_data
    else
      render json: { message: result[:message] }, status: :unprocessable_entity
    end
  end

  def destroy
    member = membershipable.members_and_requesters.find(params[:id])
    skip_subresources = !ActiveRecord::Type::Boolean.new.cast(params.delete(:remove_sub_memberships))
    # !! is used in case unassign_issuables contains empty string which would result in nil
    unassign_issuables = !!ActiveRecord::Type::Boolean.new.cast(params.delete(:unassign_issuables))

    Members::DestroyService.new(current_user).execute(member, skip_subresources: skip_subresources, unassign_issuables: unassign_issuables)

    respond_to do |format|
      format.html do
        message =
          begin
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
          end

        redirect_to members_page_url, notice: message
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
                  alert: _("Your request for access could not be processed: %{error_meesage}") %
                    { error_meesage: access_requester.errors.full_messages.to_sentence }
    end
  end

  def approve_access_request
    access_requester = membershipable.requesters.find(params[:id])
    Members::ApproveAccessRequestService
      .new(current_user, params)
      .execute(access_requester)

    redirect_to members_page_url
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def leave
    member = membershipable.members_and_requesters.find_by!(user_id: current_user.id)
    Members::DestroyService.new(current_user).execute(member)

    notice =
      if member.request?
        _("Your access request to the %{source_type} has been withdrawn.") % { source_type: source_type }
      else
        _("You left the \"%{membershipable_human_name}\" %{source_type}.") % { membershipable_human_name: membershipable.human_name, source_type: source_type }
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

  def requested_relations
    case params[:with_inherited_permissions].presence
    when 'exclude'
      [:direct]
    when 'only'
      [:inherited]
    else
      [:inherited, :direct]
    end
  end
end

MembershipActions.prepend_mod_with('MembershipActions')
