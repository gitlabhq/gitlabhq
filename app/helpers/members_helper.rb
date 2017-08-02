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
      if member.invite?
        "revoke the invitation for #{member.invite_email} to join"
      else
        "remove #{member.user.name} from"
      end

    text << action << " the #{member.source.human_name} #{member.real_source_type.humanize(capitalize: false)}?"
  end

  def remove_member_title(member)
    "Remove user from #{member.real_source_type.humanize(capitalize: false)}"
  end

  def leave_confirmation_message(member_source)
    "Are you sure you want to leave the " \
    "\"#{member_source.human_name}\" #{member_source.class.to_s.humanize(capitalize: false)}?"
  end

  def filter_group_project_member_path(options = {})
    options = params.slice(:search, :sort).merge(options)

    path = request.path
    path << "?#{options.to_param}"
    path
  end

  # Returns a `<action>_<source>_access_request` association, e.g.:
  # - destroy_project_access_request
  # - destroy_group_access_request
  def action_access_request_permission(action, access_request)
    "#{action}_#{access_request.class.name.underscore}".to_sym
  end

  def withdraw_access_request_message(access_request)
    source =
      if access_request.is_a?(ProjectAccessRequest)
        "the #{access_request.project.human_name} project"
      elsif access_request.is_a?(GroupAccessRequest)
        "the #{access_request.group.human_name} group"
      end

    "Are you sure you want to withdraw your access request for the #{source}?"
  end

  def deny_access_request_message(access_request)
    source =
      if access_request.is_a?(ProjectAccessRequest)
        "the #{access_request.project.human_name} project"
      elsif access_request.is_a?(GroupAccessRequest)
        "the #{access_request.group.human_name} group"
      end

    "Are you sure you want to deny #{access_request.user.name}'s request to join the #{source}?"
  end

  def deny_access_request_title(access_request)
    if access_request.is_a?(ProjectAccessRequest)
      "Deny access request from project"
    elsif access_request.is_a?(GroupAccessRequest)
      "Deny access request from group"
    end
  end
end
