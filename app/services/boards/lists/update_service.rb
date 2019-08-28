# frozen_string_literal: true

module Boards
  module Lists
    class UpdateService < Boards::BaseService
      def execute(list)
        return not_authorized if preferences? && !can_read?(list)
        return not_authorized if position? && !can_admin?(list)

        if update_preferences(list) || update_position(list)
          success(list: list)
        else
          error(list.errors.messages, 422)
        end
      end

      def update_preferences(list)
        return unless preferences?

        list.update_preferences_for(current_user, preferences)
      end

      def update_position(list)
        return unless position?

        move_service = Boards::Lists::MoveService.new(parent, current_user, params)

        move_service.execute(list)
      end

      def preferences
        { collapsed: Gitlab::Utils.to_boolean(params[:collapsed]) }
      end

      def not_authorized
        error("Not authorized", 403)
      end

      def preferences?
        params.has_key?(:collapsed)
      end

      def position?
        params.has_key?(:position)
      end

      def can_read?(list)
        Ability.allowed?(current_user, :read_list, parent)
      end

      def can_admin?(list)
        Ability.allowed?(current_user, :admin_list, parent)
      end
    end
  end
end
