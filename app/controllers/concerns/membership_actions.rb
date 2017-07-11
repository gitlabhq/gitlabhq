module MembershipActions
  extend ActiveSupport::Concern

  def create
    create_params = params.permit(:user_ids, :access_level, :expires_at)
    result = Members::CreateService.new(membershipable, current_user, create_params).execute

    redirect_url = members_page_url

    if result[:status] == :success
      redirect_to redirect_url, notice: 'Users were successfully added.'
    else
      redirect_to redirect_url, alert: result[:message]
    end
  end

  def destroy
    Members::DestroyService.new(membershipable, current_user, params)
      .execute(:all)

    respond_to do |format|
      format.html do
        message = "User was successfully removed from #{source_type}."
        redirect_to members_page_url, notice: message
      end

      format.js { head :ok }
    end
  end

  def request_access
    membershipable.request_access(current_user)

    redirect_to polymorphic_path(membershipable),
                notice: 'Your request for access has been queued for review.'
  end

  def approve_access_request
    member = Members::ApproveAccessRequestService.new(membershipable, current_user, params).execute

    log_audit_event(member, action: :create)

    redirect_to members_page_url
  end

  def leave
    member = Members::DestroyService.new(membershipable, current_user, user_id: current_user.id)
      .execute(:all)

    notice =
      if member.request?
        "Your access request to the #{source_type} has been withdrawn."
      else
        "You left the \"#{membershipable.human_name}\" #{source_type}."
      end

    log_audit_event(member, action: :destroy) unless member.request?

    respond_to do |format|
      format.html do
        redirect_path = member.request? ? member.source : [:dashboard, membershipable.class.to_s.tableize]
        redirect_to redirect_path, notice: notice
      end

      format.json { render json: { notice: notice } }
    end
  end

  protected

  def membershipable
    raise NotImplementedError
  end

  def log_audit_event(member, options = {})
    AuditEventService.new(current_user, membershipable, options)
      .for_member(member).security_event
  end

  def members_page_url
    if membershipable.is_a?(Project)
      project_project_members_path(membershipable)
    else
      polymorphic_url([membershipable, :members])
    end
  end

  def source_type
    @source_type ||= membershipable.class.to_s.humanize(capitalize: false)
  end
end
