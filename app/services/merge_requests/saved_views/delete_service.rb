# frozen_string_literal: true

module MergeRequests
  module SavedViews
    class DeleteService
      def initialize(saved_view, current_user:)
        @saved_view = saved_view
        @current_user = current_user
      end

      def execute
        unless Ability.allowed?(current_user, :delete_saved_view, saved_view)
          return ServiceResponse.error(
            message: _('You do not have permission to delete this saved view.'),
            reason: :forbidden
          )
        end

        if saved_view.destroy
          ServiceResponse.success(payload: { saved_view: saved_view })
        else
          ServiceResponse.error(
            message: saved_view.errors.full_messages,
            reason: :unprocessable_entity
          )
        end
      end

      private

      attr_reader :saved_view, :current_user
    end
  end
end
