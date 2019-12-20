# frozen_string_literal: true

module MembershipActions
  include MembersPresentation
  extend ActiveSupport::Concern

  def create
    create_params = params.permit(:user_ids, :access_level, :expires_at)
    result = Members::CreateService.new(current_user, create_params).execute(membershipable)

    if result[:status] == :success
      redirect_to members_page_url, notice: _('Users were successfully added.')
    else
      redirect_to members_page_url, alert: result[:message]
    end
  end

  def update
    update_params = params.require(root_params_key).permit(:access_level, :expires_at)
    member = membershipable.members_and_requesters.find(params[:id])
    member = Members::UpdateService
      .new(current_user, update_params)
      .execute(member)
      .present(current_user: current_user)

    present_members([member])
    respond_to do |format|
      format.js { render 'shared/members/update', locals: { member: member } }
    end
  end

  def destroy
    member = membershipable.members_and_requesters.find(params[:id])
    Members::DestroyService.new(current_user).execute(member)

    respond_to do |format|
      format.html do
        message =
          begin
            case membershipable
            when Namespace
              _("User was successfully removed from group and any subresources.")
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
    membershipable.request_access(current_user)

    redirect_to polymorphic_path(membershipable),
                notice: _('Your request for access has been queued for review.')
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
        redirect_path = member.request? ? member.source : [:dashboard, membershipable.class.to_s.tableize]
        redirect_to redirect_path, notice: notice
      end

      format.json { render json: { notice: notice } }
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def resend_invite
    member = membershipable.members.find(params[:id])

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

  def root_params_key
    case membershipable
    when Namespace
      :group_member
    when Project
      :project_member
    else
      raise "Unknown membershipable type: #{membershipable}!"
    end
  end

  def members_page_url
    case membershipable
    when Namespace
      polymorphic_url([membershipable, :members])
    when Project
      project_project_members_path(membershipable)
    else
      raise "Unknown membershipable type: #{membershipable}!"
    end
  end

  def source_type
    @source_type ||=
      begin
        case membershipable
        when Namespace
          _("group")
        when Project
          _("project")
        else
          raise "Unknown membershipable type: #{membershipable}!"
        end
      end
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
