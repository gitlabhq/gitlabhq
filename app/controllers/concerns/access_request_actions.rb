module AccessRequestActions
  extend ActiveSupport::Concern

  def request_access
    access_requestable_resource.request_access(current_user)

    redirect_to access_requestable_resource_path,
                notice: 'Your request for access has been queued for review.'
  end

  def approve_access_request
    @member = access_requestable_resource.public_send(member_entity_name.pluralize).request.find(params[:id])

    return render_403 unless can?(current_user, :"update_#{member_entity_name}", @member)

    @member.accept_request

    redirect_to access_requestable_resource_members_path
  end

  protected

  def access_requestable_resource
    raise NotImplementedError
  end

  def access_requestable_resource_path
    access_requestable_resource
  end

  def access_requestable_resource_members_path
    [access_requestable_resource, 'members']
  end

  def member_entity_name
    "#{access_requestable_resource.class.to_s.underscore}_member"
  end
end
