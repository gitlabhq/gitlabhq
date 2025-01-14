# frozen_string_literal: true

module MembersHelper
  include SafeFormatHelper

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
      elsif member.user
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

    "#{text} #{action} the #{member.source.human_name} #{source_text(member)}?"
  end

  def leave_confirmation_message(member_source)
    "Are you sure you want to leave the " \
      "\"#{member_source.human_name}\" #{member_source.model_name.to_s.humanize(capitalize: false)}?"
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

  def member_request_access_link(member)
    user = member.user
    member_source = member.source

    member_link = link_to user.name, user, class: :highlight
    member_role = content_tag :span, member.human_access, class: :highlight
    target_source_link = link_to member_source.human_name, polymorphic_url([member_source, :members]), class: :highlight
    target_type = member_source.model_name.singular

    safe_format(s_(
      'Notify|%{member_link} requested %{member_role} access to the %{target_source_link} %{target_type}.'
    ),
      member_link: member_link,
      member_role: member_role,
      target_source_link: target_source_link,
      target_type: target_type)
  end
end

MembersHelper.prepend_mod_with('MembersHelper')
