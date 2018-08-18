# frozen_string_literal: true

module MembersHelper
  def remove_member_message(member, user: nil)
    user = current_user if defined?(current_user)
    text = 'Are you sure you want to'

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

    "#{text} #{action} the #{member.source.human_name} #{member.real_source_type.humanize(capitalize: false)}?"
  end

  def remove_member_title(member)
    action = member.request? ? 'Deny access request' : 'Remove user'
    "#{action} from #{member.real_source_type.humanize(capitalize: false)}"
  end

  def leave_confirmation_message(member_source)
    "Are you sure you want to leave the " \
    "\"#{member_source.human_name}\" #{member_source.class.to_s.humanize(capitalize: false)}?"
  end

  def filter_group_project_member_path(options = {})
    options = params.slice(:search, :sort).merge(options)
    "#{request.path}?#{options.to_param}"
  end
end
