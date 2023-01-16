# frozen_string_literal: true

module BroadcastMessagesHelper
  include Gitlab::Utils::StrongMemoize

  def current_broadcast_banner_messages
    BroadcastMessage.current_banner_messages(
      current_path: request.path,
      user_access_level: current_user_access_level_for_project_or_group
    ).select do |message|
      cookies["hide_broadcast_message_#{message.id}"].blank?
    end
  end

  def current_broadcast_notification_message
    not_hidden_messages = BroadcastMessage.current_notification_messages(
      current_path: request.path,
      user_access_level: current_user_access_level_for_project_or_group
    ).select do |message|
      cookies["hide_broadcast_message_#{message.id}"].blank?
    end
    not_hidden_messages.last
  end

  def broadcast_message(message, opts = {})
    return unless message.present?

    render "shared/broadcast_message", { message: message, **opts }
  end

  def broadcast_message_status(broadcast_message)
    if broadcast_message.active?
      'Active'
    elsif broadcast_message.ended?
      'Expired'
    else
      'Pending'
    end
  end

  def render_broadcast_message(broadcast_message)
    if broadcast_message.notification?
      Banzai.render_field_and_post_process(broadcast_message, :message, {
        current_user: current_user,
        skip_project_check: true,
        broadcast_message_placeholders: true
      }).html_safe
    else
      Banzai.render_field(broadcast_message, :message).html_safe
    end
  end

  def target_access_level_options
    BroadcastMessage::ALLOWED_TARGET_ACCESS_LEVELS.map do |access_level|
      [Gitlab::Access.human_access(access_level), access_level]
    end
  end

  def target_access_levels_display(access_levels)
    access_levels.map do |access_level|
      Gitlab::Access.human_access(access_level)
    end.join(', ')
  end

  private

  def current_user_access_level_for_project_or_group
    return if Feature.disabled?(:role_targeted_broadcast_messages)
    return unless current_user.present?

    strong_memoize(:current_user_access_level_for_project_or_group) do
      case controller
      when Projects::ApplicationController
        next unless @project

        @project.team.max_member_access(current_user.id)
      when Groups::ApplicationController
        next unless @group

        @group.max_member_access_for_user(current_user)
      end
    end
  end
end
