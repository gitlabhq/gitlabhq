# frozen_string_literal: true

module WorkItems
  module Widgets
    module AwardEmojiService
      class UpdateService < WorkItems::Widgets::BaseService
        def before_update_in_transaction(params:)
          return unless params.present? && params.key?(:name) && params.key?(:action)
          return unless has_permission?(:award_emoji)

          service_response!(service_result(params[:action], params[:name]))
        end

        private

        def service_result(action, name)
          class_name = {
            add: ::AwardEmojis::AddService,
            remove: ::AwardEmojis::DestroyService
          }

          return invalid_action_error(action) unless class_name.key?(action)

          class_name[action].new(work_item, name, current_user).execute
        end

        def invalid_action_error(key)
          error(format(_("%{key} is not a valid action."), key: key))
        end
      end
    end
  end
end
