# frozen_string_literal: true

module MergeRequests
  module SavedViews
    class UpdateService
      ALLOWED_ATTRIBUTES = %i[name filters].freeze

      def initialize(saved_view, current_user:, params: {})
        @saved_view = saved_view
        @current_user = current_user
        @params = params
      end

      def execute
        unless Ability.allowed?(current_user, :update_saved_view, saved_view)
          return ServiceResponse.error(
            message: _('You do not have permission to update this saved view.'),
            reason: :forbidden
          )
        end

        if saved_view.update(attributes)
          ServiceResponse.success(payload: { saved_view: saved_view })
        else
          ServiceResponse.error(
            message: saved_view.errors.full_messages,
            reason: :unprocessable_entity
          )
        end
      end

      private

      attr_reader :saved_view, :current_user, :params

      def attributes
        attrs = params.slice(*ALLOWED_ATTRIBUTES)
        attrs[:filters] = attrs[:filters].to_h.deep_stringify_keys if attrs.key?(:filters)
        attrs
      end
    end
  end
end
