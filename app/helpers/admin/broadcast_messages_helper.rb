# frozen_string_literal: true

module Admin
  module BroadcastMessagesHelper
    include Gitlab::Utils::StrongMemoize

    def current_broadcast_banner_messages
      System::BroadcastMessage.current_banner_messages(
        current_path: request.path,
        user_access_level: current_user_access_level_for_project_or_group
      ).select do |message|
        cookies["hide_broadcast_message_#{message.id}"].blank?
      end
    end

    def current_broadcast_notification_message
      not_hidden_messages = System::BroadcastMessage.current_notification_messages(
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
      System::BroadcastMessage::ALLOWED_TARGET_ACCESS_LEVELS.map do |access_level|
        [Gitlab::Access.human_access(access_level), access_level]
      end
    end

    def target_access_levels_display(access_levels)
      access_levels.map do |access_level|
        Gitlab::Access.human_access(access_level)
      end.join(', ')
    end

    def admin_broadcast_messages_data(broadcast_messages)
      broadcast_messages.map do |message|
        {
          id: message.id,
          status: broadcast_message_status(message),
          message: message.message,
          theme: message.theme,
          broadcast_type: message.broadcast_type,
          dismissable: message.dismissable,
          starts_at: message.starts_at.iso8601,
          ends_at: message.ends_at.iso8601,
          target_roles: target_access_levels_display(message.target_access_levels),
          target_path: message.target_path,
          type: message.broadcast_type.capitalize,
          edit_path: edit_admin_broadcast_message_path(message),
          delete_path: "#{admin_broadcast_message_path(message)}.js"
        }
      end.to_json
    end

    def broadcast_message_data(broadcast_message)
      {
        id: broadcast_message.id,
        message: broadcast_message.message,
        broadcast_type: broadcast_message.broadcast_type,
        theme: broadcast_message.theme,
        dismissable: broadcast_message.dismissable.to_s,
        target_access_levels: broadcast_message.target_access_levels,
        messages_path: admin_broadcast_messages_path,
        preview_path: preview_admin_broadcast_messages_path,
        target_path: broadcast_message.target_path,
        starts_at: broadcast_message.starts_at.iso8601,
        ends_at: broadcast_message.ends_at.iso8601,
        target_access_level_options: target_access_level_options.to_json,
        show_in_cli: broadcast_message.show_in_cli.to_s
      }
    end

    private

    def current_user_access_level_for_project_or_group
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
end
