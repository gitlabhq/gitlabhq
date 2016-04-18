module MembersHelper
  def member_class(member)
    "#{member.source.class.to_s}Member".constantize
  end

  def members_association(entity)
    "#{entity.class.to_s.underscore}_members".to_sym
  end

  def action_member_permission(action, member)
    "#{action}_#{member.source.class.to_s.underscore}_member".to_sym
  end

  def can_see_entity_roles?(user, entity)
    return false unless user

    user.is_admin? || entity.send(members_association(entity)).exists?(user_id: user.id)
  end

  def member_path(member)
    case member.source
    when Project
      namespace_project_project_member_path(member.source.namespace, member.source, member)
    when Group
      group_group_member_path(member.source, member)
    else
      raise ArgumentError.new('Unknown object class')
    end
  end

  def resend_invite_member_path(member)
    case member.source
    when Project
      resend_invite_namespace_project_project_member_path(member.source.namespace, member.source, member)
    when Group
      resend_invite_group_group_member_path(member.source, member)
    else
      raise ArgumentError.new('Unknown object class')
    end
  end

  def request_access_path(entity)
    case entity
    when Project
      request_access_namespace_project_project_members_path(entity.namespace, entity)
    when Group
      request_access_group_group_members_path(entity)
    else
      raise ArgumentError.new('Unknown object class')
    end
  end

  def approve_request_member_path(member)
    case member.source
    when Project
      approve_namespace_project_project_member_path(member.source.namespace, member.source, member)
    when Group
      approve_group_group_member_path(member.source, member)
    else
      raise ArgumentError.new('Unknown object class')
    end
  end

  def leave_path(entity)
    case entity
    when Project
      leave_namespace_project_project_members_path(entity.namespace, entity)
    when Group
      leave_group_group_members_path(entity)
    else
      raise ArgumentError.new('Unknown object class')
    end
  end

  def withdraw_request_message(entity)
    "Are you sure you want to withdraw your access request for the \"#{entity_name(entity)}\" #{entity_type(entity)}?"
  end

  def remove_member_message(member)
    entity = member.source
    entity_type = entity_type(entity)
    entity_name = entity_name(entity)

    if member.request?
      "You are going to deny #{member.created_by.name}'s request to join the #{entity_name} #{entity_type}. Are you sure?"
    elsif member.invite?
      "You are going to revoke the invitation for #{member.invite_email} to join the #{entity_name} #{entity_type}. Are you sure?"
    else
      "You are going to remove #{member.user.name} from the #{entity_name} #{entity_type}. Are you sure?"
    end
  end

  def remove_member_title(member)
    member.request? ? 'Deny access request' : 'Remove user'
  end

  def leave_confirmation_message(entity)
    "Are you sure you want to leave \"#{entity_name(entity)}\" #{entity_type(entity)}?"
  end

  private

  def entity_type(entity)
    entity.class.to_s.underscore
  end

  def entity_name(entity)
    case entity
    when Project
      entity.name_with_namespace
    when Group
      entity.name
    else
      raise ArgumentError.new('Unknown object class')
    end
  end
end
