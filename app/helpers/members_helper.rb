module MembersHelper
  # Returns a `<action>_<source>_member` association, e.g.:
  # - admin_project_member, update_project_member, destroy_project_member
  # - admin_group_member, update_group_member, destroy_group_member
  def action_member_permission(action, member)
    "#{action}_#{member.type.underscore}".to_sym
  end

  def remove_member_message(member, user: nil)
    user = current_user if defined?(current_user)

    text = 'Are you sure you want to '
    action =
      if member.request?
        if member.user == user
          'withdraw your access request for'
        else
          "deny #{member.user.name}'s request to join"
        end
      elsif member.invite?
        "revoke the invitation for #{member.invite_email} to join"
      else
        "remove #{member.user.name} from"
      end

    text << action << " the #{member.source.human_name} #{member.real_source_type.humanize(capitalize: false)}?"
  end

  def remove_member_title(member)
    text = " from #{member.real_source_type.humanize(capitalize: false)}"

    text.prepend(member.request? ? 'Deny access request' : 'Remove user')
  end

  def leave_confirmation_message(member_source)
    "Are you sure you want to leave the " \
    "\"#{member_source.human_name}\" #{member_source.class.to_s.humanize(capitalize: false)}?"
  end
end
