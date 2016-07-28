module MembershipActions
  extend ActiveSupport::Concern

  def request_access
    membershipable.request_access(current_user)

    redirect_to polymorphic_path(membershipable),
                notice: 'Your request for access has been queued for review.'
  end

  def approve_access_request
    Members::ApproveAccessRequestService.new(membershipable, current_user, user_id: params[:id]).execute

    redirect_to polymorphic_url([membershipable, :members])
  end

  def leave
    @member = membershipable.members.find_by(user_id: current_user) ||
      membershipable.requesters.find_by(user_id: current_user)
    Members::DestroyService.new(@member, current_user).execute

    source_type = @member.real_source_type.humanize(capitalize: false)
    notice =
      if @member.request?
        "Your access request to the #{source_type} has been withdrawn."
      else
        "You left the \"#{@member.source.human_name}\" #{source_type}."
      end
    redirect_path = @member.request? ? @member.source : [:dashboard, @member.real_source_type.tableize]

    redirect_to redirect_path, notice: notice
  end

  protected

  def membershipable
    raise NotImplementedError
  end
end
