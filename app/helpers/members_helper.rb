# frozen_string_literal: true

module MembersHelper
  def remove_member_message(member, user: nil)
    user = current_user if defined?(current_user)
    text = 'Are you sure you want to'

    action =
      if member.invite?
        "revoke the invitation for #{member.invite_email} to join"
      elsif member.request?
        if member.user == user
          'withdraw your access request for'
        else
          "deny #{member.user.name}'s request to join"
        end
      else
        if member.user
          "remove #{member.user.name} from"
        else
          e = RuntimeError.new("Data integrity error: no associated user for member ID #{member.id}")
          Gitlab::ErrorTracking.track_exception(e,
            member_id: member.id,
            invite_email: member.invite_email,
            invite_accepted_at: member.invite_accepted_at,
            source_id: member.source_id,
            source_type: member.source_type)
          "remove this orphaned member from"
        end
      end

    "#{text} #{action} the #{member.source.human_name} #{source_text(member)}?"
  end

  def remove_member_title(member)
    action = member.request? ? 'Deny access request' : 'Remove user'

    "#{action} from #{source_text(member)}"
  end

  def leave_confirmation_message(member_source)
    "Are you sure you want to leave the " \
    "\"#{member_source.human_name}\" #{member_source.class.to_s.humanize(capitalize: false)}?"
  end

  def filter_group_project_member_path(options = {})
    options = params.slice(:search, :sort).merge(options).permit!
    "#{request.path}?#{options.to_param}"
  end

  def member_path(member)
    if member.is_a?(GroupMember)
      group_group_member_path(member.source, member)
    else
      project_project_member_path(member.source, member)
    end
  end

  private

  def source_text(member)
    type = member.real_source_type.humanize(capitalize: false)

    return type if member.request? || member.invite? || type != 'group'

    'group and any subresources'
  end

  def members_pagination_data(members, pagination = {})
    {
      current_page: members.respond_to?(:current_page) ? members.current_page : nil,
      per_page: members.respond_to?(:limit_value) ? members.limit_value : nil,
      total_items: members.respond_to?(:total_count) ? members.total_count : members.count,
      param_name: pagination[:param_name] || nil,
      params: pagination[:params] || {}
    }
  end
end
