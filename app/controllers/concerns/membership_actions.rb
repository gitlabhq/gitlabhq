module MembershipActions
  extend ActiveSupport::Concern

  def request_access
    membershipable.request_access(current_user)

    redirect_to polymorphic_path(membershipable),
                notice: 'Your request for access has been queued for review.'
  end

  def approve_access_request
    member = Members::ApproveAccessRequestService.new(membershipable, current_user, params).execute

    log_audit_event(member, action: :create)

    redirect_to polymorphic_url([membershipable, :members])
  end

  def leave
    member = Members::DestroyService.new(membershipable, current_user, user_id: current_user.id).
      execute(:all)

    source_type = membershipable.class.to_s.humanize(capitalize: false)
    notice =
      if member.request?
        "Your access request to the #{source_type} has been withdrawn."
      else
        "You left the \"#{membershipable.human_name}\" #{source_type}."
      end

    log_audit_event(member, action: :destroy) unless member.request?

    redirect_path = member.request? ? member.source : [:dashboard, membershipable.class.to_s.tableize]

    redirect_to redirect_path, notice: notice
  end

  protected

  def membershipable
    raise NotImplementedError
  end

  def log_audit_event(member, options = {})
    AuditEventService.new(current_user, membershipable, options).
      for_member(member).security_event
  end
end
