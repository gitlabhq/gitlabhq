# frozen_string_literal: true

module MergeRequests
  module SavedViews
    class CreateService
      def initialize(current_user:, params: {})
        @current_user = current_user
        @params = params
      end

      def execute
        unless Ability.allowed?(current_user, :create_saved_view, current_user)
          return ServiceResponse.error(
            message: _('You do not have permission to create saved views.'),
            reason: :forbidden
          )
        end

        saved_view = ::MergeRequests::SavedView.new(
          user: current_user,
          name: params[:name],
          filters: normalized_filters
        )

        if persist(saved_view)
          ServiceResponse.success(payload: { saved_view: saved_view })
        else
          ServiceResponse.error(
            message: saved_view.errors.full_messages,
            reason: :unprocessable_entity
          )
        end
      end

      private

      attr_reader :current_user, :params

      def persist(saved_view)
        current_user.with_lock { saved_view.save }
      end

      def normalized_filters
        params[:filters].to_h.deep_stringify_keys
      end
    end
  end
end
