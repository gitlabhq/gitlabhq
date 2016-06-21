module MembershipActions
  extend ActiveSupport::Concern
  include MembersHelper

  def request_access
    membershipable.request_access(current_user)

    redirect_to polymorphic_path(membershipable),
                notice: 'Your request for access has been queued for review.'
  end

  def approve_access_request
    @member = membershipable.members.request.find(params[:id])

    return render_403 unless can?(current_user, action_member_permission(:update, @member), @member)

    @member.accept_request

    log_audit_event(@member, action: :create)

    redirect_to polymorphic_url([membershipable, :members])
  end

  def leave
    @member = membershipable.members.find_by(user_id: current_user)
    return render_403 unless @member

    source_type = @member.real_source_type.humanize(capitalize: false)

    if can?(current_user, action_member_permission(:destroy, @member), @member)
      notice =
        if @member.request?
          "Your access request to the #{source_type} has been withdrawn."
        else
          "You left the \"#{@member.source.human_name}\" #{source_type}."
        end
      @member.destroy

      log_audit_event(@member, action: :destroy) unless @member.request?

      redirect_to [:dashboard, @member.real_source_type.tableize], notice: notice
    else
      if cannot_leave?
        alert = "You can not leave the \"#{@member.source.human_name}\" #{source_type}."
        alert << " Transfer or delete the #{source_type}."
        redirect_to polymorphic_url(membershipable), alert: alert
      else
        render_403
      end
    end
  end

  protected

  def membershipable
    raise NotImplementedError
  end

  def cannot_leave?
    raise NotImplementedError
  end

  def log_audit_event(member, options = {})
    AuditEventService.new(current_user, membershipable, options).
      for_member(member).security_event
  end
end
