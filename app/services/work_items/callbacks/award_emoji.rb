# frozen_string_literal: true

module WorkItems
  module Callbacks
    class AwardEmoji < Base
      def before_update
        return unless params.present? && params.key?(:name) && params.key?(:action)
        return unless has_permission?(:award_emoji)

        execute_emoji_service(params[:action], params[:name])
      end

      private

      def execute_emoji_service(action, name)
        class_name = {
          add: ::AwardEmojis::AddService,
          remove: ::AwardEmojis::DestroyService,
          toggle: ::AwardEmojis::ToggleService
        }

        raise_error(invalid_action_error(action)) unless class_name.key?(action)

        result = class_name[action].new(work_item, name, current_user).execute

        raise_error(result[:message]) if result[:status] == :error
      end

      def invalid_action_error(key)
        format(_("%{key} is not a valid action."), key: key)
      end
    end
  end
end
