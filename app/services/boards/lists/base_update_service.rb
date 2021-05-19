# frozen_string_literal: true

module Boards
  module Lists
    class BaseUpdateService < Boards::BaseService
      extend ::Gitlab::Utils::Override

      def execute(list)
        if execute_by_params(list)
          success(list: list)
        else
          message = list.errors.empty? ? 'The update was not successful.' : list.errors.messages

          error(message, { list: list })
        end
      end

      private

      override :error
      def error(message, pass_back = {})
        ServiceResponse.error(message: message, http_status: :unprocessable_entity, payload: pass_back)
      end

      override :success
      def success(pass_back = {})
        ServiceResponse.success(payload: pass_back)
      end

      def execute_by_params(list)
        update_preferences_result = update_preferences(list) if can_read?(list)
        update_position_result = update_position(list) if can_admin?(list)

        update_preferences_result || update_position_result
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

      def preferences?
        params.has_key?(:collapsed)
      end

      def position?
        params.has_key?(:position)
      end

      def can_read?(list)
        raise NotImplementedError
      end

      def can_admin?(list)
        raise NotImplementedError
      end
    end
  end
end
